class UserModel {
  String uid;
  String username;
  String fullname;
  String email;
  String phonenumber;
  String address;

  UserModel(
      {required this.uid,
      required this.username,
      required this.fullname,
      required this.email,
      required this.phonenumber,
      required this.address});

  // Convert a UserModel object into a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'fullname': fullname,
      'email': email,
      'phonenumber': phonenumber,
      'address': address,
    };
  }

  // Create a UserModel object from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      fullname: map['fullname'] ?? '',
      email: map['email'] ?? '',
      phonenumber: map['phonenumber'] ?? '',
      address: map['address'] ?? '',
    );
  }
}
