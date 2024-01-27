import 'package:amazon_app/storage/storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'user.dart';

class UserController {
  const UserController();

  static final db = FirebaseFirestore.instance;
  static const uuid = Uuid();
  static const collectionPath = 'users';

  static Future<void> create({
    required String docId,
    String? accountId,
    String? name,
    String? image,
    String? description,
  }) async {
    final doc = db.collection(collectionPath).doc(docId);

    final userSnapshot = await db
        .collection(collectionPath)
        .where('account_id', isEqualTo: accountId)
        .get();

    while (true) {
      accountId = uuid.v4();
      if (userSnapshot.docs.isEmpty) {
        break;
      }
    }

    if (name is! String) {
      name = 'no name';
    }

    String? imagePath;
    if (image is! String) {
      imagePath = 'src/images/group_img.jpeg';
    } else {
      imagePath =
          await StorageController.uploadUserImageToStorage(docId, image);
    }

    if (description is! String) {
      description = null;
    }

    final createdAt = FieldValue.serverTimestamp();

    await doc.set({
      'account_id': accountId,
      'name': name,
      'image': imagePath,
      'description': description,
      'created_at': createdAt,
    });
  }

  static Future<UserProfile> read(String docId) async {
    final userDoc = await db.collection(collectionPath).doc(docId).get();
    final userRef = userDoc.data();
    if (userRef == null) {
      throw Exception('Error : No found document data.');
    }

    var accountId = userRef['account_id'];
    if (accountId is! String) {
      accountId = accountId.toString();
    }

    var name = userRef['name'];
    if (name is! String) {
      name = name.toString();
    }

    var image = userRef['image'];
    if (image is! String) {
      image = image.toString();
    }

    var description = userRef['description'];
    description = description as String?;

    var updatedAt = userRef['updated_at'];
    updatedAt = updatedAt as Timestamp?;

    var createdAt = userRef['created_at'];
    if (createdAt is! Timestamp) {
      createdAt = createdAt as Timestamp;
    }

    return UserProfile(
      accountId: accountId,
      name: name,
      image: image,
      description: description,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }

  static Future<List<UserProfile>> readWithAccountId(String accountId) async {
    final userSnapshot = await db
        .collection(collectionPath)
        .where('account_id', isEqualTo: accountId)
        .get();

    final userRefs = userSnapshot.docs.map((doc) {
      final userDocRef = doc.data() as Map<String, dynamic>?;
      if (userDocRef == null) {
        throw Exception('Error : No found document data.');
      }
      var name = userDocRef['name'];
      if (name is! String) {
        name = name.toString();
      }

      var image = userDocRef['image'];
      if (image is! String) {
        image = image.toString();
      }

      var description = userDocRef['description'];
      description = description as String?;

      var updatedAt = userDocRef['updated_at'];
      updatedAt = updatedAt as Timestamp?;

      var createdAt = userDocRef['created_at'];
      if (createdAt is! Timestamp) {
        createdAt = createdAt as Timestamp;
      }

      return UserProfile(
        accountId: accountId,
        name: name,
        image: image,
        description: description,
        updatedAt: updatedAt,
        createdAt: createdAt,
      );
    }).toList();

    return userRefs;
  }

  static Future<String> readUserDocIdWithAccountId(String accountId) async {
    final userSnapshot = await db
        .collection(collectionPath)
        .where('account_id', isEqualTo: accountId)
        .get();
    
    if (userSnapshot.docs.isEmpty) {
      throw Exception('Error: No document found for the user account ID.');
    }
     final userDoc = userSnapshot.docs.first;

    final userDocRef = userDoc.data() as Map<String, dynamic>?;
    if (userDocRef == null) {
        throw Exception('Error: No found document data.');
    }

    return userDoc.id;
  }

  ///後で、factoryメソッドなどを用いて、ユーザーの名前、画像、説明などを個別で変更できる関数を生成する。
  ///メールアドレスとaccountIdの変更機能はこの関数では行わない。
  static Future<void> update(
    String docId,
    String name,
    String image,
    String description,
  ) async {
    final imagePath =
        await StorageController.uploadUserImageToStorage(docId, image);
    if (imagePath == null) {
      return;
    }

    final updatedAt = FieldValue.serverTimestamp();
    final updateData = <String, dynamic>{
      'name': name,
      'image': imagePath,
      'description': description,
      'updated_at': updatedAt,
    };

    await db.collection(collectionPath).doc(docId).update(updateData);
  }

  static Future<bool> updateAccountId(String docId, String accountId) async {
    final snapshot = await db
        .collection(collectionPath)
        .where('account_id', isEqualTo: accountId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      debugPrint('The account ID is already used');
      return false;
    }

    final updateData = <String, String>{
      'account_id': accountId,
    };

    await db.collection(collectionPath).doc(docId).update(updateData);
    debugPrint('Successfully changed account ID');
    return true;
  }

  ///テーブルはこの関数で削除できるが、authenticationには反映されない。
  static Future<void> delete(String docId) async {
    await db.collection(collectionPath).doc(docId).delete();
  }
}