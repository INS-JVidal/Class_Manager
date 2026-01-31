import 'package:mongo_dart/mongo_dart.dart';

import '../../models/recurring_holiday.dart';
import '../datasources/mongodb_datasource.dart';

/// Repository for RecurringHoliday CRUD operations.
class RecurringHolidayRepository {
  RecurringHolidayRepository(this._datasource);

  final MongoDbDatasource _datasource;

  DbCollection get _collection => _datasource.collection('recurring_holidays');

  Future<List<RecurringHoliday>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map((doc) => RecurringHoliday.fromJson(doc)).toList();
  }

  Future<RecurringHoliday?> findById(String id) async {
    final doc = await _collection.findOne(where.eq('_id', id));
    return doc != null ? RecurringHoliday.fromJson(doc) : null;
  }

  Future<RecurringHoliday> insert(RecurringHoliday holiday) async {
    await _collection.insertOne(holiday.toJson());
    return holiday;
  }

  Future<RecurringHoliday> update(RecurringHoliday holiday) async {
    await _collection.replaceOne(where.eq('_id', holiday.id), holiday.toJson());
    return holiday;
  }

  Future<void> delete(String id) async {
    await _collection.deleteOne(where.eq('_id', id));
  }

  Future<List<RecurringHoliday>> findEnabled() async {
    final docs = await _collection.find(where.eq('isEnabled', true)).toList();
    return docs.map((doc) => RecurringHoliday.fromJson(doc)).toList();
  }
}
