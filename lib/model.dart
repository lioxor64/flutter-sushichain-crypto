mixin ToModel{}

/// Tiny type container
class Model<T>{
  T value;
  Model(this.value);

  bool operator ==(o) =>
      o is Model && o.value == value;

  int get hashCode => value.hashCode;

  String toString() => value.toString();
}

class Wif = Model<String> with ToModel;
class HexPublicKey = Model<String> with ToModel;
class HexPrivateKey = Model<String> with ToModel;
class Address = Model<String> with ToModel;
class NetworkPrefix = Model<String> with ToModel;

class Source = Model<String> with ToModel;
class CipherText = Model<String> with ToModel;
class Salt = Model<String> with ToModel;