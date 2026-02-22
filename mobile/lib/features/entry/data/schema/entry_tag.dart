import 'package:sqflite/sqflite.dart';

Future<void> run(Database db) async {
  await db.execute('''
  CREATE TABLE IF NOT EXISTS entry_tag (
    entry_id TEXT NOT NULL REFERENCES entry (id),
    tag_id TEXT NOT NULL REFERENCES tag (id),
    PRIMARY KEY (entry_id, tag_id)
  );
  ''');
  await db.execute('''
  CREATE INDEX IF NOT EXISTS entry_tag_tag_id ON entry_tag (tag_id);
  ''');
}
