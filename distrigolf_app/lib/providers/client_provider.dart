import 'package:flutter/material.dart';
import '../models/client.dart';
import '../repositories/client_repository.dart';

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repository;

  List<ClientModel> _clientes = [];
  ClientModel? _clienteSeleccionado;
  bool _loading = false;
  String? _error;
  String _busqueda = '';

  ClientProvider(this._repository);

  List<ClientModel> get clientes => _filtrarClientes();
  ClientModel? get clienteSeleccionado => _clienteSeleccionado;
  bool get loading => _loading;
  String? get error => _error;
  String get busqueda => _busqueda;

  List<ClientModel> _filtrarClientes() {
    if (_busqueda.isEmpty) return _clientes;
    final query = _busqueda.toLowerCase();
    return _clientes.where((c) {
      return c.nombre.toLowerCase().contains(query) ||
          (c.codigo?.toLowerCase().contains(query) ?? false) ||
          (c.ciudad?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> cargarClientes(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _clientes = await _repository.obtenerClientes(userId);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> seleccionarCliente(int id) async {
    _clienteSeleccionado = await _repository.obtenerCliente(id);
    notifyListeners();
  }

  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    notifyListeners();
  }

  void clearSelection() {
    _clienteSeleccionado = null;
    notifyListeners();
  }
}
