import 'package:bloc_provider/bloc_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'company_disclosure_bloc2.dart';

class TagsDisclosureBloc extends Bloc {
  final String tag;
  final FirestoreGetCount<DocumentSnapshot> disclosure;

  TagsDisclosureBloc._({
    @required this.tag,
    @required this.disclosure,
  });

  factory TagsDisclosureBloc(
      {@required String tag, @required ValueStream<User> user$}) {
    final disclosure = FirestoreGetCount<DocumentSnapshot<Map<String,dynamic>>>(
        user$: user$,
        query: FirebaseFirestore.instance
            .collection('disclosures')
            .where('tags2', arrayContains: tag)
            .orderBy('time', descending: true),
        mapper: (doc) => doc,
        getFn: (doc) => doc.data()['time']);

    return TagsDisclosureBloc._(tag: tag, disclosure: disclosure);
  }

  @override
  void dispose() {
    this.disclosure.dispose();
  }
}
