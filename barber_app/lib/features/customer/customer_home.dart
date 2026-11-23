import 'package:flutter/material.dart';
import '../../app/settings.dart';
import '../../app/strings.dart';
import '../../app/strings_pro.dart';
import '../../app/ui_kit.dart';
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
  late final CustomerApi _api;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _api = CustomerApi(SettingsScope.read(context));
  }

  @override
  Widget build(BuildContext context) {
    final st = SettingsScope.of(context);
    final z = Z(st.lang);
    Widget tabBtn(int i, IconData icon, String label) => Expanded(
          child: GradientButton(
            compact: true,
            outlined: _tab != i,
            icon: icon,
            label: label,
            onPressed: () => setState(() => _tab = i),
          ),
        );
    return GlassScaffold(
      title: S(st.lang).t('app_name'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => st.setRole(null),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        ),
      ],
      body: Column(
        children: [
          const UpdateBanner(app: 'customer'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                tabBtn(0, Icons.storefront_rounded, z.t('tab_shops')),
                const SizedBox(width: 10),
                tabBtn(1, Icons.event_available_rounded, z.t('tab_bookings')),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? ShopsTab(api: _api, onBooked: () => setState(() => _tab = 1))
                : MyBookingsTab(api: _api),
          ),
        ],
      ),
    );
  }
}
