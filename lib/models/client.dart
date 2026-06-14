class Client {
  final int id;
  final String name;
  final String documentNumber;
  final bool isSynced;
  final int? serverId;

  Client(this.id, this.name, this.documentNumber, this.isSynced, this.serverId);

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      map['id'],
      map['name'].toString(),
      map['document_number'].toString(),
      map['is_synced'] == 1,
      map['server_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'document_number': documentNumber,
      'is_synced': isSynced ? 1 : 0,
      'server_id': serverId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'document_number': documentNumber,
    };
  }
}