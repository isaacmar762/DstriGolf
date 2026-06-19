import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/price.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/sync_log.dart';

class LocalDbService {
  static Database? _database;
  bool _disponible = true;

  Future<Database?> get database async {
    if (!_disponible) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDb();
      return _database!;
    } catch (e) {
      _disponible = false;
      debugPrint('Local DB no disponible: $e');
      return null;
    }
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'distrigolf_local.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  bool get disponible => _disponible;

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes_local (
        id INTEGER PRIMARY KEY,
        codigo TEXT,
        dv TEXT,
        nombre TEXT NOT NULL,
        direccion TEXT,
        email TEXT,
        ciudad TEXT,
        zona_id INTEGER,
        zona_nombre TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE productos_local (
        id INTEGER PRIMARY KEY,
        referencia TEXT NOT NULL,
        nombre TEXT NOT NULL,
        cod_linea TEXT,
        nombre_linea TEXT,
        cod_medida TEXT,
        volumen REAL,
        grados REAL,
        imagen_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE precios_local (
        id INTEGER PRIMARY KEY,
        producto_id INTEGER NOT NULL,
        tipo_vendedor TEXT NOT NULL,
        esquema TEXT,
        bruto REAL DEFAULT 0,
        unitario REAL DEFAULT 0,
        max_descuento REAL DEFAULT 0,
        minimo REAL DEFAULT 0,
        impuestos REAL DEFAULT 0,
        FOREIGN KEY (producto_id) REFERENCES productos_local(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pedidos_local (
        id TEXT PRIMARY KEY,
        vendedor_id TEXT NOT NULL,
        cliente_id INTEGER NOT NULL,
        fecha TEXT,
        estado TEXT DEFAULT 'BORRADOR',
        total REAL DEFAULT 0,
        firma TEXT,
        notas TEXT,
        latitud REAL,
        longitud REAL,
        sincronizado INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE detalle_pedido_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id TEXT NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (pedido_id) REFERENCES pedidos_local(id),
        FOREIGN KEY (producto_id) REFERENCES productos_local(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id TEXT NOT NULL,
        accion TEXT NOT NULL,
        estado TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_pedidos_sincronizado ON pedidos_local(sincronizado)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE productos_local ADD COLUMN imagen_url TEXT');
    }
  }

  // ─── Clientes ───────────────────────────────────────────────────

  Future<void> guardarClientes(List<ClientModel> clientes) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('clientes_local');
    for (final c in clientes) {
      batch.insert('clientes_local', c.toLocalMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ClientModel>> obtenerClientes() async {
    final db = await database;
    if (db == null) return [];
    final res = await db.query('clientes_local', orderBy: 'nombre');
    return res.map((e) => ClientModel.fromMap(e)).toList();
  }

  Future<ClientModel?> obtenerCliente(int id) async {
    final db = await database;
    if (db == null) return null;
    final res = await db.query('clientes_local', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return ClientModel.fromMap(res.first);
  }

  // ─── Productos ──────────────────────────────────────────────────

  Future<void> guardarProductos(List<ProductModel> productos) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('productos_local');
    for (final p in productos) {
      batch.insert('productos_local', p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> obtenerProductos({String? linea}) async {
    final db = await database;
    if (db == null) return [];
    final where = linea != null ? 'nombre_linea = ?' : null;
    final whereArgs = linea != null ? [linea] : null;
    final res = await db.query('productos_local',
        where: where, whereArgs: whereArgs, orderBy: 'nombre');
    return res.map((e) => ProductModel.fromMap(e)).toList();
  }

  // ─── Precios ────────────────────────────────────────────────────

  Future<void> guardarPrecios(List<PriceModel> precios, String tipoVendedor) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('precios_local', where: 'tipo_vendedor = ?', whereArgs: [tipoVendedor]);
    for (final p in precios) {
      batch.insert('precios_local', {
        ...p.toMap(),
        'tipo_vendedor': tipoVendedor,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<PriceModel?> obtenerPrecio(int productoId, String tipoVendedor) async {
    final db = await database;
    if (db == null) return null;
    final res = await db.query('precios_local',
        where: 'producto_id = ? AND tipo_vendedor = ?',
        whereArgs: [productoId, tipoVendedor]);
    if (res.isEmpty) return null;
    return PriceModel.fromMap(res.first);
  }

  // ─── Pedidos (Offline) ──────────────────────────────────────────

  Future<String> crearPedidoLocal(OrderModel pedido) async {
    final db = await database;
    final id = pedido.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (db == null) return id;
    await db.insert('pedidos_local', {
      ...pedido.toMap(),
      'id': id,
      'sincronizado': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> agregarDetalleLocal(List<OrderItemModel> items) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('detalle_pedido_local', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<OrderModel>> obtenerPedidosPendientes() async {
    final db = await database;
    if (db == null) return [];
    final res = await db.query('pedidos_local',
        where: 'sincronizado = 0', orderBy: 'fecha DESC');
    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<List<OrderModel>> obtenerTodosPedidosLocales() async {
    final db = await database;
    if (db == null) return [];
    final res = await db.query('pedidos_local', orderBy: 'fecha DESC');
    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<OrderModel?> obtenerPedidoLocal(String id) async {
    final db = await database;
    if (db == null) return null;
    final pedidos = await db.query('pedidos_local', where: 'id = ?', whereArgs: [id]);
    if (pedidos.isEmpty) return null;
    final pedido = OrderModel.fromMap(pedidos.first);

    final detalles = await db.query('detalle_pedido_local',
        where: 'pedido_id = ?', whereArgs: [id]);
    final items = detalles.map((e) => OrderItemModel.fromMap(e)).toList();

    return OrderModel(
      id: pedido.id,
      vendedorId: pedido.vendedorId,
      clienteId: pedido.clienteId,
      fecha: pedido.fecha,
      estado: pedido.estado,
      total: pedido.total,
      firma: pedido.firma,
      notas: pedido.notas,
      latitud: pedido.latitud,
      longitud: pedido.longitud,
      items: items,
    );
  }

  Future<void> marcarSincronizado(String pedidoId) async {
    final db = await database;
    if (db == null) return;
    await db.update('pedidos_local', {'sincronizado': 1},
        where: 'id = ?', whereArgs: [pedidoId]);
  }

  Future<void> actualizarEstadoPedidoLocal(String pedidoId, String estado) async {
    final db = await database;
    if (db == null) return;
    await db.update('pedidos_local', {'estado': estado},
        where: 'id = ?', whereArgs: [pedidoId]);
  }

  Future<void> actualizarFirmaLocal(String pedidoId, String firma) async {
    final db = await database;
    if (db == null) return;
    await db.update('pedidos_local', {'firma': firma},
        where: 'id = ?', whereArgs: [pedidoId]);
  }

  // ─── Sync Log ──────────────────────────────────────────────────

  Future<void> registrarSync(SyncLog log) async {
    final db = await database;
    if (db == null) return;
    await db.insert('sync_log', log.toMap());
  }

  Future<List<SyncLog>> obtenerSyncLog() async {
    final db = await database;
    if (db == null) return [];
    final res = await db.query('sync_log', orderBy: 'created_at DESC', limit: 50);
    return res.map((e) => SyncLog.fromMap(e)).toList();
  }

  // ─── Limpieza ───────────────────────────────────────────────────

  Future<void> limpiarDatos() async {
    final db = await database;
    if (db == null) return;
    await db.delete('detalle_pedido_local');
    await db.delete('pedidos_local');
    await db.delete('precios_local');
    await db.delete('productos_local');
    await db.delete('clientes_local');
  }
}
