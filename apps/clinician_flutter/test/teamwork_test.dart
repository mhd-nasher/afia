/// D-014 tests — fake RTDB backend: presence add/remove, the request
/// lifecycle (pending→accepted→done; declined terminal), rules-shaped
/// payloads, and ward-order behavior incl. §2.10 (no risk mode exists).
library;

import 'dart:async';

import 'package:afia_clinician/domain/entities.dart';
import 'package:afia_clinician/domain/chips.dart';
import 'package:afia_clinician/domain/handover.dart';
import 'package:afia_clinician/domain/teamwork.dart';
import 'package:afia_clinician/domain/ward_order.dart';
import 'package:afia_clinician/services/teamwork/teamwork_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBackend implements TeamworkBackend {
  final Map<String, Map<String, Object?>> presence = {};
  final Map<String, Map<String, Map<String, Object?>>> requests = {};
  final _presenceController =
      StreamController<List<PresenceEntry>>.broadcast();
  final Map<String, StreamController<List<ShiftRequest>>> _requestControllers =
      {};
  int now = 1000;
  int _pushCounter = 0;

  @override
  Object get serverTimestamp => now;

  void _emitPresence() {
    _presenceController.add([
      for (final e in presence.entries)
        PresenceEntry.fromMap(e.key, e.value.cast<Object?, Object?>()),
    ]);
  }

  void _emitRequests(String wardId) {
    _requestControllers[wardId]?.add([
      for (final e in (requests[wardId] ?? {}).entries)
        ShiftRequest.fromMap(e.key, wardId, e.value.cast<Object?, Object?>()),
    ]);
  }

  @override
  Future<void> setPresence(String uid, Map<String, Object?> payload) async {
    presence[uid] = payload;
    _emitPresence();
  }

  @override
  Future<void> heartbeat(String uid, Object serverTimestamp) async {
    presence[uid]?['lastSeen'] = serverTimestamp;
    _emitPresence();
  }

  @override
  Future<void> removePresence(String uid) async {
    presence.remove(uid);
    _emitPresence();
  }

  @override
  Stream<List<PresenceEntry>> presenceStream() => _presenceController.stream;

  @override
  Future<String> pushRequest(
      String wardId, Map<String, Object?> payload) async {
    final id = 'req${_pushCounter++}';
    (requests[wardId] ??= {})[id] = Map.of(payload);
    _emitRequests(wardId);
    return id;
  }

  @override
  Future<void> updateRequestStatus(String wardId, String requestId,
      RequestStatus status, Object respondedAt) async {
    final r = requests[wardId]?[requestId];
    if (r == null) throw StateError('no such request');
    r['status'] = status.wire;
    r['respondedAt'] = respondedAt;
    _emitRequests(wardId);
  }

  @override
  Stream<List<ShiftRequest>> requestsStream(String wardId) =>
      (_requestControllers[wardId] ??=
              StreamController<List<ShiftRequest>>.broadcast())
          .stream;
}

Patient patient(String id, String bed) => Patient(
      id: id,
      externalIdentifier: null,
      createdAt: 0,
      name: 'P $id',
      dateOfBirth: '1950-01-01',
      wardId: 'ward-a',
      bed: bed,
    );

void main() {
  group('presence (fake backend)', () {
    test('goOnline writes a rules-shaped node; goOffline removes it', () async {
      final backend = FakeBackend();
      final service = TeamworkService(backend);
      await service.goOnline(
          uid: 'u1', name: 'Amara', role: 'charge_nurse', wardId: 'ward-a');

      final node = backend.presence['u1']!;
      // The exact children /database.rules.json validates.
      expect(node.keys,
          containsAll(['name', 'role', 'wardId', 'lastSeen']));
      expect(node['name'], 'Amara');
      expect(node['wardId'], 'ward-a');

      await service.goOffline();
      expect(backend.presence.containsKey('u1'), isFalse);
    });

    test('wardPresence filters to MY ward only — never a directory', () async {
      final backend = FakeBackend();
      final service = TeamworkService(backend);
      final futureList = service.wardPresence('ward-a').first;
      await backend.setPresence('u1', buildPresencePayload(
          name: 'A', role: 'nurse', wardId: 'ward-a', serverTimestamp: 1));
      await backend.setPresence('u2', buildPresencePayload(
          name: 'B', role: 'nurse', wardId: 'ward-b', serverTimestamp: 2));
      final list = await futureList;
      expect(list.map((p) => p.uid), ['u1']);
    });
  });

  group('request lifecycle (fake backend)', () {
    test('payload is rules-shaped and pending; note is capped at 80', () async {
      final backend = FakeBackend();
      final service = TeamworkService(backend);
      await service.sendRequest(
        from: const RequestParty(uid: 'u1', name: 'Amara'),
        to: const RequestParty(uid: 'u2', name: 'Jonas'),
        wardId: 'ward-a',
        kind: RequestKind.medWitness,
        bed: 'A4',
        note: 'x' * 200,
      );
      final payload = backend.requests['ward-a']!.values.single;
      expect(payload.keys,
          containsAll(['from', 'to', 'kind', 'createdAt', 'status']));
      expect(payload['kind'], 'med_witness');
      expect(payload['status'], 'pending');
      expect((payload['note'] as String).length, 80);
      expect((payload['from'] as Map)['uid'], 'u1');
      expect((payload['to'] as Map)['uid'], 'u2');
    });

    test('pending → accepted → done; respondedAt recorded', () async {
      final backend = FakeBackend();
      final service = TeamworkService(backend);
      final id = await backend.pushRequest(
          'ward-a',
          buildRequestPayload(
            from: const RequestParty(uid: 'u1', name: 'A'),
            to: const RequestParty(uid: 'u2', name: 'B'),
            kind: RequestKind.liftTurn,
            serverTimestamp: 1,
          ));
      ShiftRequest current() => ShiftRequest.fromMap('req0', 'ward-a',
          backend.requests['ward-a']![id]!.cast<Object?, Object?>());

      await service.respond(current(), RequestStatus.accepted);
      expect(current().status, RequestStatus.accepted);
      expect(current().respondedAt, isNotNull);

      await service.respond(current(), RequestStatus.done);
      expect(current().status, RequestStatus.done);
    });

    test('illegal transitions are rejected before any write', () async {
      final backend = FakeBackend();
      final service = TeamworkService(backend);
      final id = await backend.pushRequest(
          'ward-a',
          buildRequestPayload(
            from: const RequestParty(uid: 'u1', name: 'A'),
            to: const RequestParty(uid: 'u2', name: 'B'),
            kind: RequestKind.supplies,
            serverTimestamp: 1,
          ));
      ShiftRequest current() => ShiftRequest.fromMap(id, 'ward-a',
          backend.requests['ward-a']![id]!.cast<Object?, Object?>());

      // pending → done is not allowed (must accept first).
      expect(() => service.respond(current(), RequestStatus.done),
          throwsStateError);

      await service.respond(current(), RequestStatus.declined);
      // declined is terminal.
      expect(() => service.respond(current(), RequestStatus.accepted),
          throwsStateError);
      expect(() => service.respond(current(), RequestStatus.done),
          throwsStateError);
    });

    test('transition table is exactly the D-014 lifecycle', () {
      expect(canTransition(RequestStatus.pending, RequestStatus.accepted), isTrue);
      expect(canTransition(RequestStatus.pending, RequestStatus.declined), isTrue);
      expect(canTransition(RequestStatus.pending, RequestStatus.done), isFalse);
      expect(canTransition(RequestStatus.accepted, RequestStatus.done), isTrue);
      expect(canTransition(RequestStatus.accepted, RequestStatus.declined), isFalse);
      expect(canTransition(RequestStatus.declined, RequestStatus.done), isFalse);
      expect(canTransition(RequestStatus.done, RequestStatus.pending), isFalse);
    });
  });

  group('ward order (D-014 feature 1, §2.10 intact)', () {
    Handover draft(String patientId,
            {int chips = 0, bool signed = false}) =>
        Handover(
          id: 'h-$patientId',
          externalIdentifier: null,
          createdAt: 1,
          patientId: patientId,
          authorId: 'me',
          status:
              signed ? HandoverStatus.queued : HandoverStatus.draftReady,
          audio: null,
          transcript: '',
          fields: const [],
          chips: [
            for (var i = 0; i < chips; i++)
              ConfirmableChip(
                  id: 'c$i',
                  kind: ChipKindTest.drug,
                  text: 'x',
                  start: 0,
                  end: 1,
                  match: null,
                  confirmedBy: null,
                  confirmedAt: null,
                  correctedTo: null),
          ],
          flags: const [],
          signature: signed
              ? const Signature(
                  practitionerId: 'me',
                  signatureIdentity: 'RN X',
                  signedAt: 1,
                  openFlagReason: null)
              : null,
          version: 1,
          supersedes: null,
          supersededBy: null,
          exportError: null,
          acknowledgedAt: null,
        );

    final patients = [patient('p1', 'A1'), patient('p2', 'A2'), patient('p3', 'A3')];

    test('no risk mode exists in the enum (§2.10 structural)', () {
      expect(WardOrderMode.values.map((m) => m.wire),
          unorderedEquals(['bed', 'unsigned_first', 'unconfirmed_chips_first', 'manual']));
      expect(WardOrderModeWire.parse('risk'), isNull);
      expect(WardOrderModeWire.parse('severity'), isNull);
    });

    test('unsigned_first groups unsigned before signed, bed order within', () {
      final handovers = {'p2': draft('p2', signed: true)};
      final ordered = applyWardOrder(
          const WardOrder(mode: WardOrderMode.unsignedFirst),
          patients,
          (id) => handovers[id]);
      expect(ordered.map((p) => p.id), ['p1', 'p3', 'p2']);
    });

    test('unconfirmed_chips_first sorts by count desc then bed', () {
      final handovers = {
        'p2': draft('p2', chips: 3),
        'p3': draft('p3', chips: 1),
      };
      final ordered = applyWardOrder(
          const WardOrder(mode: WardOrderMode.unconfirmedChipsFirst),
          patients,
          (id) => handovers[id]);
      expect(ordered.map((p) => p.id), ['p2', 'p3', 'p1']);
    });

    test('manual respects the nurse\'s order; unknown ids appended by bed', () {
      final ordered = applyWardOrder(
          const WardOrder(
              mode: WardOrderMode.manual, manualIds: ['p3', 'p1', 'ghost']),
          patients,
          (_) => null);
      expect(ordered.map((p) => p.id), ['p3', 'p1', 'p2']);
    });

    test('serialization round-trips (persistence)', () {
      const order =
          WardOrder(mode: WardOrderMode.manual, manualIds: ['p2', 'p1']);
      final restored = WardOrder.deserialize(order.serialize());
      expect(restored.mode, WardOrderMode.manual);
      expect(restored.manualIds, ['p2', 'p1']);
      expect(WardOrder.deserialize(null).isDefault, isTrue);
      expect(WardOrder.deserialize('garbage').isDefault, isTrue);
    });
  });
}

/// ChipKind lives in chips.dart; a tiny alias keeps the fake terse.
class ChipKindTest {
  static const drug = ChipKind.drug;
}
