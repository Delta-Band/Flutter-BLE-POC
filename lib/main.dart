import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import './home.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice _connectedDevice;
  List<BluetoothService> _services;
  bool _searchingForDevice;
  bool _connectingToDevice;
  bool _blueToothIsDisabled;
  int _timeToConnect;

  _connectToDevice(BluetoothDevice device) async {
    DateTime startTime = DateTime.now();
    StreamSubscription<BluetoothDeviceState> _listener;

    flutterBlue.stopScan();

    try {
      await device.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        print('device already connected!');
        throw e;
      }
    } finally {
      print('device connection established!');
      _services = await device.discoverServices();
      setState(() {
        DateTime now = DateTime.now();
        Duration differance = startTime.difference(now);
        _timeToConnect = 0 - differance.inSeconds;
        _connectedDevice = device;
        _connectingToDevice = false;
      });
    }

    if (_listener != null) {
      _listener.cancel();
    }
    _listener = _connectedDevice.state.listen((state) {
      if (state == BluetoothDeviceState.disconnected) {
        print('Device Disconnected!');
        flutterBlue.startScan();
        setState(() {
          _connectingToDevice = false;
          _connectedDevice = null;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _searchingForDevice = true;
    _connectingToDevice = true;
    _blueToothIsDisabled = true;
    flutterBlue.state.listen((state) {
      if (state == BluetoothState.off) {
        if (!_blueToothIsDisabled) {
          setState(() {
            _blueToothIsDisabled = true;
          });
        }
      } else if (state == BluetoothState.on) {
        if (_blueToothIsDisabled) {
          setState(() {
            _blueToothIsDisabled = false;
          });
        }
        flutterBlue.startScan();
      }
    });
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        if (device.name == 'JBL Flip 4') {
          _connectToDevice(device);
        }
      }
    });
    flutterBlue.scanResults.listen((List<ScanResult> results) async {
      for (ScanResult result in results) {
        if (result.device.name == 'JBL Flip 4') {
          _connectToDevice(result.device);
        }
      }
    });
    flutterBlue.isScanning.listen((isScanning) {
      setState(() {
        _searchingForDevice = isScanning;
      });
    });
  }

  Widget _buildSearchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Searching for device...\n(Make sure it\'s turned on)',
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 30.0,
          ),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connecting to device...'),
            SizedBox(
              height: 30.0,
            ),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnOnBluetooth() {
    return Center(
      child: Text(
        'Your Phone\'s bloothooth is turned off.\nPlease turn in on.',
        textAlign: TextAlign.center,
        // style: TextStyle(height: 2),
      ),
    );
  }

  Widget _buildView() {
    if (_blueToothIsDisabled) {
      return _buildTurnOnBluetooth();
    } else if (_searchingForDevice) {
      return _buildSearchingState();
    } else if (_connectingToDevice) {
      return _buildConnectingState();
    }
    return MyHomePage(
      services: _services,
      timeToConnect: _timeToConnect,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter BLE Demo',
        darkTheme: ThemeData.dark(),
        theme: ThemeData(
            primarySwatch: Colors.grey,
            textTheme: TextTheme(
              bodyText1: TextStyle(
                height: 2,
                color: Colors.white,
              ),
              bodyText2: TextStyle(
                height: 2,
                color: Colors.white,
              ),
            )),
        home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Flutter BLE Demo',
              style: TextStyle(color: Color(0xffFF0048)),
            ),
            brightness: Brightness.dark,
          ),
          body: Container(
            color: Colors.grey.shade800,
            child: _buildView(),
          ),
        ),
      );
}
