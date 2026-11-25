import 'package:flutter/material.dart';
import '../../app/brand.dart';
import '../../app/settings.dart';
import '../../app/strings_s6.dart';
import '../../app/widgets.dart';
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
    final shopsTab = st.lang == 'fa'
        ? 'کسب‌وکارها'
        : (st.lang == 'ar' ? 'الأنشطة التجارية' : 'Businesses');
    return GlassScaffold(
      title: appNameFor(st.lang),
      maxWidth: 720,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: SegmentPicker<int>(
              options: <MapEntry<int, String>>[
                MapEntry<int, String>(0, shopsTab),
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
