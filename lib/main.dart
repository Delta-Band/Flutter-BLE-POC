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
  BluetoothDevice _device;
  List<BluetoothService> _services;
  bool _isScanning;
  bool _connectingToDevice;
  bool _blueToothIsDisabled;
  int _timeToConnect;
  StreamSubscription<BluetoothDeviceState> _deviceListener;

  _connectToDevice() async {
    try {
      setState(() {
        _connectingToDevice = true;
        _services = null;
      });
      DateTime startTime = DateTime.now();
      print('*** Attepting connection...');
      await _device.disconnect();
      await _device.connect(timeout: Duration(seconds: 10), autoConnect: false);
      // await _device.connect();
      print('*** device connection established!');
      DateTime now = DateTime.now();
      Duration differance = startTime.difference(now);
      setState(() {
        _timeToConnect = 0 - differance.inSeconds;
      });
    } catch (e) {
      if (e.message == 'Future not completed') {
        print(
            '*** Connection taking more than 19 seconds - attrepting reconnect');
        _connectToDevice();
      } else if (e.code != 'already_connected') {
        print('*** device already connected!');
        // throw e;
      }
    }
  }

  void _listenToDeviceState(device) {
    _deviceListener = device.state.listen((state) async {
      if (state == BluetoothDeviceState.disconnected) {
        print('*** Device Disconnected!');
        setState(() {
          _services = null;
          _timeToConnect = null;
        });
        // await flutterBlue.stopScan();
        // flutterBlue.startScan();
        // _scanner();
        if (!_isScanning) {
          flutterBlue.startScan();
        }
      } else if (state == BluetoothDeviceState.connected) {
        // flutterBlue.stopScan();
        print('*** Requesting service from device...');
        _services = await device.discoverServices();
        setState(() {
          _connectingToDevice = false;
        });
        flutterBlue.stopScan();
      }
    });
    setState(() {});
  }

  void _scanner() {
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        print('*** Device is already connected so pair with app');
        if (device.name == 'JBL Flip 4') {
          setState(() {
            _device = device;
          });
          _listenToDeviceState(device);
          if (!_connectingToDevice) {
            _connectToDevice();
          }
        }
      }
    });
    flutterBlue.scanResults.listen((List<ScanResult> results) async {
      for (ScanResult result in results) {
        if (result.device.name == 'JBL Flip 4') {
          print('*** Found the device');
          setState(() {
            _device = result.device;
          });
          _listenToDeviceState(result.device);
          if (!_connectingToDevice) {
            _connectToDevice();
          }
        }
      }
    });
    flutterBlue.isScanning.listen((isScanning) {
      setState(() {
        _isScanning = isScanning;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _isScanning = false;
    _connectingToDevice = false;
    _blueToothIsDisabled = true;
    flutterBlue.state.listen((state) {
      if (state == BluetoothState.off) {
        if (!_blueToothIsDisabled) {
          setState(() {
            _blueToothIsDisabled = true;
            _device = null;
            _services = null;
            _timeToConnect = null;
            _connectingToDevice = false;
          });
        }
      } else if (state == BluetoothState.on) {
        if (_blueToothIsDisabled) {
          setState(() {
            _blueToothIsDisabled = false;
          });
          _scanner();
          flutterBlue.startScan();
        }
        // if (!_isScanning) {
        //   flutterBlue.startScan();
        // }
      }
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
    } else if (_connectingToDevice) {
      return _buildConnectingState();
    } else if (_services != null && _timeToConnect != null) {
      return MyHomePage(
        services: _services,
        timeToConnect: _timeToConnect,
      );
      // return Center(
      //   child: Text('Connected to JBK Flip 4!'),
      // );
    } else if (_isScanning) {
      return _buildSearchingState();
    }
    return SizedBox(
      height: 30.0,
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
