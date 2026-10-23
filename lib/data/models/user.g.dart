// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('User', json, ($checkedConvert) {
      final val = User(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String?),
        website: $checkedConvert('website', (v) => v as String?),
        company: $checkedConvert(
          'company',
          (v) => v == null ? null : Company.fromJson(v as Map<String, dynamic>),
        ),
        address: $checkedConvert(
          'address',
          (v) => v == null ? null : Address.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'website': instance.website,
  'company': instance.company?.toJson(),
  'address': instance.address?.toJson(),
};

Company _$CompanyFromJson(Map<String, dynamic> json) => Company(
  name: json['name'] as String,
  catchPhrase: json['catchPhrase'] as String?,
  bs: json['bs'] as String?,
);

Map<String, dynamic> _$CompanyToJson(Company instance) => <String, dynamic>{
  'name': instance.name,
  'catchPhrase': instance.catchPhrase,
  'bs': instance.bs,
};

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: json['street'] as String?,
  suite: json['suite'] as String?,
  city: json['city'] as String?,
  zipcode: json['zipcode'] as String?,
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'suite': instance.suite,
  'city': instance.city,
  'zipcode': instance.zipcode,
};
