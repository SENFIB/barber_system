import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';
import '../settings/settings_page.dart';
import 'customer_api.dart';
import 'customer_bookings.dart';
import 'customer_shops.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;
  final ValueNotifier<int> _refresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final t = T6(st.lang);
    final api = CustomerApi(st);
    return GlassScaffold(
      title: t.t('app_name'),
      maxWidth: 720,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentPicker<int>(
              options: <MapEntry<int, String>>[
                MapEntry<int, String>(0, t.t('cu_tab_shops')),
                MapEntry<int, String>(1, t.t('cu_tab_mine')),
              ],
              value: _tab,
              onChanged: (v) {
                setState(() => _tab = v);
                if (v == 1) _refresh.value++;
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                ShopsTab(
                  api: api,
                  onBooked: () {
                    setState(() => _tab = 1);
                    _refresh.value++;
                  },
                ),
                MyBookingsTab(api: api, refresh: _refresh),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
