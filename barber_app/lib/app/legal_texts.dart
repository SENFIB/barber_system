// متن حریم خصوصی و شرایط استفاده در سه زبان.
// نسخه را وقتی بالا ببری که متن تغییر مهم کرد؛ آن‌وقت از همه دوباره تأیید گرفته می‌شود.
import 'registry.dart';

const int kLegalVersion = 1;

/// شماره یا ایمیل تماس. وقتی فرم پیام فعال باشد (kRegistryUrl پر باشد) نمایش داده نمی‌شود.
const String kLegalContact = 'efmfib.1373@gmail.com';

class LegalSection {
  final String h;
  final String b;
  const LegalSection(this.h, this.b);
}

class LegalGroup {
  final String title;
  final List<LegalSection> sections;
  const LegalGroup(this.title, this.sections);
}

/// جملهٔ پایانی؛ فقط یک بار، زیر «شرایط استفاده».
LegalSection _closing(String lang) {
  if (lang == 'ar') {
    return const LegalSection(
        'هذا ليس مجرد نظام لحجز المواعيد؛ بل محاولة لبناء تجربة أفضل وعمل أكثر تنظيمًا ومستقبل أكثر إشراقًا.',
        'آمل أن تكون هذه المنصة رفيقًا موثوقًا في مسار نموّكم ونجاحكم.\n\nPowered by ESMAIL\n— إسماعيل');
  }
  if (lang == 'en') {
    return const LegalSection(
        'This is not just a booking system; it is an attempt to build a better experience, a more organized business and a brighter future.',
        'I hope this platform will be a trustworthy companion on your path to growth and success.\n\nPowered by ESMAIL\n— Esmaeil');
  }
  return const LegalSection(
      'این فقط یک سیستم نوبت‌دهی نیست؛ تلاشی است برای ساختن تجربه‌ای بهتر، کسب‌وکاری منظم‌تر و آینده‌ای روشن‌تر.',
      'امیدوارم این پلتفرم، همراهی قابل اعتماد در مسیر رشد و موفقیت شما باشد.\n\nPowered by ESMAIL\n— اسماعیل');
}

List<LegalSection> appPolicy(String lang) {
  final base = lang == 'ar' ? _arP : (lang == 'en' ? _enP : _faP);
  final list = List<LegalSection>.of(base);
  // اگر فرم پیام فعال نیست، ایمیل را نشان بده
  if (kRegistryUrl.trim().isEmpty && kLegalContact.trim().isNotEmpty) {
    final last = list.removeLast();
    list.add(LegalSection(last.h, '${last.b}\n${kLegalContact.trim()}'));
  }
  return list;
}

List<LegalSection> appTerms(String lang) {
  final base = lang == 'ar' ? _arT : (lang == 'en' ? _enT : _faT);
  return <LegalSection>[...base, _closing(lang)];
}

// =========================================================== فارسی
const List<LegalSection> _faP = [
  LegalSection('۱. معرفی',
      'ESMAIRO (اسمایرو) برنامهٔ نوبت‌دهی آنلاین برای آرایشگاه‌ها و مشتریان آن‌هاست. این متن توضیح می‌دهد چه اطلاعاتی گرفته می‌شود، برای چه کاری استفاده می‌شود، چه کسی آن را می‌بیند و تا کی نگه داشته می‌شود. با تأیید این متن و استفاده از برنامه، آن را می‌پذیرید.'),
  LegalSection('۲. اطلاعاتی که گرفته می‌شود',
      'مشتری:\n• نام و شماره تلفنی که خودتان وارد می‌کنید (روی دستگاه خودتان ذخیره می‌شود و هنگام ثبت نوبت برای آرایشگاه ارسال می‌شود).\n• یک شناسهٔ تصادفی دستگاه که فقط برای نمایش نوبت‌های خودتان به‌کار می‌رود و ربطی به هویت واقعی شما ندارد.\n• اطلاعات نوبت: آرایشگاه، آرایشگر، خدمت، تاریخ و ساعت، وضعیت نوبت و امتیازی که می‌دهید.\n\nآرایشگاه:\n• نام، شماره تماس، نشانی، شهر و (در پلن‌هایی که امکانش را دارند) عکس آرایشگاه.\n• نام کاربری و رمز عبور مدیر و آرایشگران؛ رمز عبور هرگز به‌صورت متن اصلی ذخیره نمی‌شود و فقط نسخهٔ رمزنگاری‌شدهٔ یک‌طرفه نگهداری می‌شود.\n• فهرست آرایشگران، خدمت‌ها، ساعت کاری، مرخصی‌ها، نوبت‌ها، کد لایسنس و وضعیت اشتراک.'),
  LegalSection('۳. اطلاعاتی که گرفته نمی‌شود',
      '• موقعیت مکانی دقیق دستگاه (GPS)، مخاطبین، پیامک‌ها، میکروفن و دوربین.\n• هیچ تبلیغی در برنامه نیست و اطلاعات شما برای ردیابی تبلیغاتی استفاده نمی‌شود.\n• به فایل‌های دستگاه فقط وقتی دسترسی داده می‌شود که خودتان برای عکس آرایشگاه یا پس‌زمینهٔ برنامه فایلی انتخاب کنید.'),
  LegalSection('۴. استفاده از اطلاعات',
      'اطلاعات فقط برای این کارها استفاده می‌شود: ثبت، نمایش، تغییر و لغو نوبت؛ نمایش نوبت‌ها به آرایشگاه و آرایشگر مربوط؛ محاسبهٔ امتیازها؛ بررسی لایسنس و اشتراک آرایشگاه‌ها؛ و زمان‌بندی یادآوری‌ها روی دستگاه خودتان. اطلاعات شما فروخته نمی‌شود و برای تبلیغات یا هدف دیگری در اختیار کسی قرار نمی‌گیرد.'),
  LegalSection('۵. چه کسی اطلاعات را می‌بیند',
      '• آرایشگاهی که در آن نوبت گرفته‌اید، نام، شماره تلفن و جزئیات نوبت شما را می‌بیند. آرایشگر عادی فقط نوبت‌های خودش را می‌بیند.\n• امتیازها ناشناس هستند و آرایشگاه نمی‌داند چه کسی امتیاز داده است.\n• مشتریان از اطلاعات یکدیگر چیزی نمی‌بینند.\n• توسعه‌دهنده فقط برای پشتیبانی و رفع مشکل فنی ممکن است به پایگاه داده دسترسی داشته باشد و از آن برای هدف دیگری استفاده نمی‌کند.\n• اگر مرجع قانونی یا قضایی صالح رسماً درخواست کند، ممکن است ملزم به ارائهٔ اطلاعات شویم.'),
  LegalSection('۶. محل نگهداری و امنیت',
      'اطلاعات روی سرویس‌های ابری گوگل نگهداری می‌شود و ممکن است سرورهای آن خارج از کشور باشد. ارتباط برنامه با سرور رمزنگاری‌شده (HTTPS) است، رمزها به‌صورت رمزنگاری‌شدهٔ یک‌طرفه نگهداری می‌شوند و ورود آرایشگاه‌ها با توکن امن انجام می‌شود. با این حال هیچ سیستم آنلاینی صددرصد امن نیست و نمی‌توانیم امنیت مطلق را تضمین کنیم. اگر فونت اضافی انتخاب کنید، فایل آن فونت از سرورهای گوگل دریافت می‌شود.'),
  LegalSection('۷. مدت نگهداری',
      '• نوبت‌های گذشته به‌طور خودکار پاک می‌شوند: حدود ۷ روز بعد در پلن پایه، ۱۴ روز در پرو و ۳۰ روز در ویژه (از تاریخ نوبت).\n• نوبت‌های آینده تا زمان برگزاری یا لغو نگه داشته می‌شوند.\n• اطلاعات آرایشگاه تا زمانی که فعال است نگهداری می‌شود.\n• نام و شماره‌ای که روی دستگاه خودتان ذخیره شده تا وقتی حذف نکنید باقی می‌ماند.'),
  LegalSection('۸. یادآوری‌ها و پیام‌ها',
      'یادآوری نوبت، هشدار پایان اشتراک و پیام‌های آرایشگاه برای مشتریانش روی خود دستگاه زمان‌بندی و نمایش داده می‌شود؛ پیامک یا پیام‌رسان بیرونی استفاده نمی‌شود. هر زمان از تنظیمات دستگاه می‌توانید اعلان‌ها را خاموش کنید. پیام‌های آرایشگاه فقط برای کسانی نمایش داده می‌شود که از طریق برنامه نوبت گرفته‌اند.'),
  LegalSection('۹. حقوق شما',
      '• در تنظیمات برنامه می‌توانید ببینید چه چیزی روی دستگاه ذخیره شده و همه را (از جمله نام و شماره) حذف کنید.\n• حذف اطلاعات دستگاه، نوبت‌های ثبت‌شده روی سرور را فوراً پاک نمی‌کند؛ آن‌ها طبق مدت بالا خودکار پاک می‌شوند. برای حذف زودتر با آرایشگاه یا توسعه‌دهنده تماس بگیرید.\n• هر زمان می‌توانید استفاده از برنامه را متوقف کنید.'),
  LegalSection('۱۰. کودکان',
      'برنامه برای کودکان طراحی نشده است. کاربران زیر ۱۸ سال باید با اطلاع و نظارت والدین یا سرپرست خود از آن استفاده کنند.'),
  LegalSection('۱۱. تغییر این متن',
      'ممکن است این متن به‌روز شود. در تغییرهای مهم، پیش از ادامهٔ استفاده دوباره از شما تأیید گرفته می‌شود.'),
  LegalSection('۱۲. ارتباط',
      'برای سؤال، شکایت یا درخواست حذف اطلاعات با توسعه‌دهنده تماس بگیرید.'),
];

const List<LegalSection> _faT = [
  LegalSection('۱. ماهیت برنامه',
      'ESMAIRO فقط ابزار نوبت‌دهی است. خدمتی که انجام می‌شود توافق بین آرایشگاه و مشتری است. توسعه‌دهنده در قبال کیفیت خدمت، قیمت‌ها، ساعت کاری، تأخیر یا حاضر نشدن هیچ‌یک از طرفین مسئولیتی ندارد.'),
  LegalSection('۲. تعهدات مشتری',
      '• اطلاعات درست وارد کنید و نوبت صوری یا مزاحم ثبت نکنید.\n• اگر نمی‌توانید بیایید، در مهلتی که آرایشگاه تعیین کرده (پیش‌فرض تا ۲ ساعت قبل) نوبت را لغو کنید.\n• امتیاز را صادقانه و بدون توهین بدهید.'),
  LegalSection('۳. تعهدات آرایشگاه',
      '• اطلاعات آرایشگاه، خدمت‌ها، قیمت‌ها و ساعت کاری را درست و به‌روز نگه دارید.\n• از اطلاعات مشتریان فقط برای هماهنگی همان نوبت استفاده کنید؛ فروش، انتشار یا ارسال پیام تبلیغاتی مزاحم با این اطلاعات ممنوع است.\n• نام کاربری، رمز عبور و کدهای دعوت را محرمانه نگه دارید؛ هر اقدام با آن‌ها به نام شما ثبت می‌شود.\n• قوانین کشور و صنف خود را رعایت کنید؛ رسیدگی به شکایت مشتریان با خود آرایشگاه است.\n• قوانین اختصاصی هر آرایشگاه مکمل این متن است و نمی‌تواند با آن در تناقض باشد.'),
  LegalSection('۴. لایسنس و اشتراک',
      '• هر کد لایسنس فقط برای یک آرایشگاه است و قابل انتقال یا فروش مجدد نیست.\n• اشتراک ماهانه (۳۰ روزه) است. با پایان اعتبار، بخش آرایشگاه قفل می‌شود و با وارد کردن کد جدید دوباره فعال می‌شود؛ مهلت اضافه وجود ندارد.\n• لایسنس غیرفعال‌شده دوباره خودکار فعال نمی‌شود.\n• پرداخت خارج از برنامه انجام می‌شود و برنامه اطلاعات بانکی شما را نمی‌گیرد.\n• توسعه‌دهنده می‌تواند در صورت سوءاستفاده یا نقض این شرایط، لایسنس را غیرفعال کند.'),
  LegalSection('۵. استفادهٔ ممنوع',
      '• دور زدن محدودیت‌ها، لایسنس یا امنیت برنامه؛ مهندسی معکوس یا کپی برنامه.\n• ارسال درخواست‌های انبوه یا هر کاری که سرویس را برای دیگران مختل کند.\n• سوءاستفاده از امتیازدهی یا ثبت نوبت‌های جعلی.\n• درج محتوای توهین‌آمیز، گمراه‌کننده یا خلاف قانون در نام، توضیحات، عکس یا پیام‌ها.'),
  LegalSection('۶. در دسترس بودن سرویس',
      'سرویس روی زیرساخت گوگل اجرا می‌شود؛ ممکن است گاهی کند، محدود یا قطع باشد (از جمله به‌دلیل محدودیت‌های اینترنت). کارکرد بدون وقفه تضمین نمی‌شود. توصیه می‌کنیم نوبت‌های مهم را جای دیگری هم یادداشت کنید.'),
  LegalSection('۷. محدودیت مسئولیت',
      'تا حدی که قانون اجازه می‌دهد، توسعه‌دهنده مسئول خسارت‌های غیرمستقیم، از دست رفتن درآمد یا نوبت، اختلاف بین مشتری و آرایشگاه یا مشکلات ناشی از قطعی اینترنت و سرویس‌های ثالث نیست. برنامه «به همان صورتی که هست» ارائه می‌شود.'),
  LegalSection('۸. تغییر و پایان استفاده',
      'شرایط ممکن است تغییر کند و در تغییرهای مهم دوباره تأیید می‌گیریم. در صورت نقض شرایط، دسترسی شما می‌تواند محدود شود.'),
];

// =========================================================== English
const List<LegalSection> _enP = [
  LegalSection('1. Introduction',
      'ESMAIRO is an online appointment-booking app for barber shops and their customers. This text explains what information is collected, what it is used for, who can see it, and how long it is kept. By accepting this text and using the app, you agree to it.'),
  LegalSection('2. Information we collect',
      'Customers:\n• The name and phone number you enter yourself (stored on your own device and sent to the shop when you book).\n• A random device ID used only to show your own bookings; it is not linked to your real identity.\n• Booking details: shop, barber, service, date and time, booking status and the rating you give.\n\nShops:\n• Name, phone number, address, city and (on plans that include it) the shop photo.\n• Usernames and passwords of the manager and barbers; passwords are never stored in plain text, only a one-way encrypted version is kept.\n• List of barbers, services, working hours, time off, bookings, license code and subscription status.'),
  LegalSection('3. Information we do not collect',
      '• Your precise location (GPS), contacts, text messages, microphone or camera.\n• There are no ads in the app and your data is not used for ad tracking.\n• Device files are accessed only when you yourself pick a file for the shop photo or the app background.'),
  LegalSection('4. How information is used',
      'Information is used only to: create, show, change and cancel bookings; show bookings to the relevant shop and barber; calculate ratings; verify shop licenses and subscriptions; and schedule reminders on your own device. Your information is not sold and is not given to anyone for advertising or any other purpose.'),
  LegalSection('5. Who can see your information',
      '• The shop where you booked can see your name, phone number and booking details. A regular barber sees only their own bookings.\n• Ratings are anonymous; the shop does not know who gave them.\n• Customers cannot see each other\'s information.\n• The developer may access the database only for support and fixing technical problems, and does not use it for any other purpose.\n• We may be required to disclose information if a competent legal or judicial authority officially requests it.'),
  LegalSection('6. Storage and security',
      'Data is stored on Google cloud services, whose servers may be located outside your country. Communication between the app and the server is encrypted (HTTPS), passwords are stored in one-way encrypted form, and shops sign in using secure tokens. Even so, no online system is 100% secure and we cannot guarantee absolute security. If you choose an extra font, its file is downloaded from Google servers.'),
  LegalSection('7. Retention',
      '• Past bookings are deleted automatically: about 7 days after the booking date on the Basic plan, 14 days on Pro and 30 days on Special.\n• Upcoming bookings are kept until they take place or are cancelled.\n• Shop information is kept while the shop is active.\n• The name and number saved on your own device stay until you delete them.'),
  LegalSection('8. Reminders and messages',
      'Booking reminders, subscription-expiry warnings and shop messages to its customers are scheduled and shown on the device itself; no SMS or external messenger is used. You can turn notifications off at any time in your device settings. Shop messages are shown only to people who booked through the app.'),
  LegalSection('9. Your rights',
      '• In the app settings you can see what is stored on your device and delete all of it (including your name and number).\n• Deleting device data does not instantly erase bookings already stored on the server; they are deleted automatically within the periods above. For faster removal, contact the shop or the developer.\n• You may stop using the app at any time.'),
  LegalSection('10. Children',
      'The app is not designed for children. Users under 18 should use it with the knowledge and supervision of a parent or guardian.'),
  LegalSection('11. Changes to this text',
      'This text may be updated. For important changes, we will ask for your acceptance again before you continue using the app.'),
  LegalSection('12. Contact',
      'For questions, complaints or data-deletion requests, contact the developer.'),
];

const List<LegalSection> _enT = [
  LegalSection('1. Nature of the app',
      'ESMAIRO is only a booking tool. The service itself is an agreement between the shop and the customer. The developer is not responsible for the quality of service, prices, working hours, or lateness or absence of either party.'),
  LegalSection('2. Customer obligations',
      '• Enter correct information and do not make fake or nuisance bookings.\n• If you cannot come, cancel within the period the shop sets (by default up to 2 hours before).\n• Rate honestly and without insults.'),
  LegalSection('3. Shop obligations',
      '• Keep shop information, services, prices and working hours correct and up to date.\n• Use customer information only to coordinate that booking; selling it, publishing it or sending nuisance advertising with it is forbidden.\n• Keep usernames, passwords and invite codes confidential; any action taken with them is recorded as yours.\n• Obey the laws and trade rules of your country; handling customer complaints is the shop\'s own responsibility.\n• A shop\'s own rules complement this text and cannot contradict it.'),
  LegalSection('4. License and subscription',
      '• Each license code is for one shop only and cannot be transferred or resold.\n• The subscription is monthly (30 days). When it ends, the shop panel locks and is reactivated by entering a new code; there is no grace period.\n• A deactivated license is never reactivated automatically.\n• Payment is made outside the app and the app does not collect your banking details.\n• The developer may deactivate a license in case of abuse or breach of these terms.'),
  LegalSection('5. Prohibited use',
      '• Bypassing limits, licensing or security of the app; reverse engineering or copying the app.\n• Sending mass requests or doing anything that disrupts the service for others.\n• Abusing ratings or making fake bookings.\n• Posting insulting, misleading or unlawful content in names, descriptions, photos or messages.'),
  LegalSection('6. Service availability',
      'The service runs on Google infrastructure and may sometimes be slow, limited or unavailable (including because of internet restrictions). Uninterrupted operation is not guaranteed. We recommend noting important appointments elsewhere too.'),
  LegalSection('7. Limitation of liability',
      'To the extent permitted by law, the developer is not liable for indirect damages, lost income or appointments, disputes between customer and shop, or problems caused by internet outages and third-party services. The app is provided "as is".'),
  LegalSection('8. Changes and termination',
      'These terms may change and we will ask for acceptance again for important changes. If the terms are breached, your access may be restricted.'),
];

// =========================================================== العربية
const List<LegalSection> _arP = [
  LegalSection('١. مقدمة',
      'ESMAIRO (إسمايرو) تطبيق لحجز المواعيد عبر الإنترنت للصالونات وزبائنها. يوضّح هذا النص ما المعلومات التي تُجمع، ولماذا، ومن يراها، ومدة الاحتفاظ بها. بموافقتك على هذا النص واستخدامك للتطبيق فإنك تقبله.'),
  LegalSection('٢. المعلومات التي تُجمع',
      'الزبون:\n• الاسم ورقم الهاتف اللذان تدخلهما بنفسك (يُحفظان على جهازك ويُرسلان إلى الصالون عند حجز موعد).\n• معرّف عشوائي للجهاز يُستخدم فقط لعرض مواعيدك، ولا علاقة له بهويتك الحقيقية.\n• بيانات الموعد: الصالون والحلّاق والخدمة والتاريخ والوقت وحالة الموعد والتقييم الذي تمنحه.\n\nالصالون:\n• الاسم ورقم الهاتف والعنوان والمدينة، وصورة الصالون (في الخطط التي تتيحها).\n• اسم المستخدم وكلمة المرور للمدير والحلّاقين؛ لا تُحفظ كلمة المرور نصًّا صريحًا، بل نسخة مشفّرة أحادية الاتجاه فقط.\n• قائمة الحلّاقين والخدمات وساعات العمل والإجازات والمواعيد ورمز الترخيص وحالة الاشتراك.'),
  LegalSection('٣. المعلومات التي لا تُجمع',
      '• الموقع الدقيق للجهاز (GPS) وجهات الاتصال والرسائل النصية والميكروفون والكاميرا.\n• لا توجد إعلانات في التطبيق، ولا تُستخدم بياناتك للتتبّع الإعلاني.\n• لا يُسمح بالوصول إلى ملفات الجهاز إلا عندما تختار بنفسك ملفًّا لصورة الصالون أو لخلفية التطبيق.'),
  LegalSection('٤. استخدام المعلومات',
      'تُستخدم المعلومات فقط في: تسجيل المواعيد وعرضها وتعديلها وإلغائها؛ إظهار المواعيد للصالون والحلّاق المعنيّ؛ احتساب التقييمات؛ التحقق من ترخيص الصالونات واشتراكها؛ وجدولة التذكيرات على جهازك. لا تُباع معلوماتك ولا تُعطى لأحد لأغراض إعلانية أو غيرها.'),
  LegalSection('٥. من يرى المعلومات',
      '• الصالون الذي حجزت لديه يرى اسمك ورقم هاتفك وتفاصيل موعدك. أما الحلّاق العادي فيرى مواعيده هو فقط.\n• التقييمات مجهولة الهوية ولا يعرف الصالون من قام بها.\n• لا يرى الزبائن معلومات بعضهم.\n• قد يطّلع المطوّر على قاعدة البيانات لأغراض الدعم وإصلاح الأعطال فقط، ولا يستخدمها لغرض آخر.\n• قد نُلزم بتقديم المعلومات إذا طلبت ذلك رسميًّا جهة قانونية أو قضائية مختصة.'),
  LegalSection('٦. مكان التخزين والأمان',
      'تُخزَّن المعلومات على خدمات Google السحابية، وقد تكون خوادمها خارج البلد. الاتصال بين التطبيق والخادم مشفّر (HTTPS)، وكلمات المرور تُحفظ بشكل مشفّر أحادي الاتجاه، ويتم دخول الصالونات برمز أمان (توكن). ومع ذلك لا يوجد نظام إلكتروني آمن بنسبة ١٠٠٪ ولا يمكننا ضمان أمان مطلق. وإذا اخترت خطًّا إضافيًّا فسيُنزَّل ملفه من خوادم Google.'),
  LegalSection('٧. مدة الاحتفاظ',
      '• تُحذف المواعيد السابقة تلقائيًّا: بعد نحو ٧ أيام في الخطة الأساسية، و١٤ يومًا في الاحترافية، و٣٠ يومًا في المميّزة (من تاريخ الموعد).\n• تُحفظ المواعيد القادمة حتى موعدها أو إلغائها.\n• تُحفظ معلومات الصالون ما دام نشطًا.\n• يبقى الاسم والرقم المخزّنان على جهازك إلى أن تحذفهما.'),
  LegalSection('٨. التذكيرات والرسائل',
      'تُجدوَل التذكيرات (موعدك، قرب انتهاء الاشتراك، ورسائل الصالون لزبائنه) وتُعرض على الجهاز نفسه؛ ولا تُستخدم رسائل SMS أو تطبيقات مراسلة خارجية. يمكنك إيقاف الإشعارات في أي وقت من إعدادات الجهاز. تُعرض رسائل الصالون فقط لمن حجزوا عبر التطبيق.'),
  LegalSection('٩. حقوقك',
      '• من إعدادات التطبيق يمكنك معرفة ما هو مخزّن على جهازك وحذفه بالكامل (بما في ذلك الاسم والرقم).\n• حذف بيانات الجهاز لا يمسح فورًا المواعيد المسجّلة على الخادم؛ فهي تُحذف تلقائيًّا وفق المدد أعلاه. وللحذف الأسرع تواصل مع الصالون أو المطوّر.\n• يمكنك التوقف عن استخدام التطبيق في أي وقت.'),
  LegalSection('١٠. الأطفال',
      'التطبيق غير مصمَّم للأطفال. على من هم دون ١٨ عامًا استخدامه بعلم أولياء أمورهم وإشرافهم.'),
  LegalSection('١١. تعديل هذا النص',
      'قد يُحدَّث هذا النص. عند التغييرات المهمة سنطلب موافقتك مجددًا قبل متابعة الاستخدام.'),
  LegalSection('١٢. التواصل',
      'للأسئلة أو الشكاوى أو طلب حذف البيانات تواصل مع المطوّر.'),
];

const List<LegalSection> _arT = [
  LegalSection('١. طبيعة التطبيق',
      'ESMAIRO أداة لحجز المواعيد فقط. الخدمة المقدَّمة اتفاق بين الصالون والزبون، ولا يتحمل المطوّر أي مسؤولية عن جودة الخدمة أو الأسعار أو ساعات العمل أو تأخّر أي طرف أو عدم حضوره.'),
  LegalSection('٢. التزامات الزبون',
      '• أدخل معلومات صحيحة ولا تحجز مواعيد وهمية أو مزعجة.\n• إن تعذّر حضورك فألغِ الموعد خلال المهلة التي يحدّدها الصالون (افتراضيًّا حتى ساعتين قبله).\n• قيّم بصدق ودون إساءة.'),
  LegalSection('٣. التزامات الصالون',
      '• أبقِ معلومات الصالون والخدمات والأسعار وساعات العمل صحيحة ومحدّثة.\n• استخدم معلومات الزبائن فقط لتنسيق موعدهم؛ يُمنع بيعها أو نشرها أو إرسال رسائل ترويجية مزعجة بها.\n• حافظ على سرّية اسم المستخدم وكلمة المرور ورموز الدعوة؛ فكل إجراء بها يُسجَّل باسمك.\n• التزم بقوانين بلدك ومهنتك؛ والنظر في شكاوى الزبائن مسؤولية الصالون نفسه.\n• القواعد الخاصة بكل صالون مكمِّلة لهذا النص ولا يجوز أن تتعارض معه.'),
  LegalSection('٤. الترخيص والاشتراك',
      '• كل رمز ترخيص لصالون واحد فقط ولا يجوز نقله أو إعادة بيعه.\n• الاشتراك شهري (٣٠ يومًا). عند انتهائه تُقفل لوحة الصالون وتُفعَّل من جديد بإدخال رمز جديد؛ ولا توجد مهلة إضافية.\n• الترخيص الملغى لا يُعاد تفعيله تلقائيًّا.\n• يتم الدفع خارج التطبيق ولا يجمع التطبيق بياناتك المصرفية.\n• يحق للمطوّر إلغاء الترخيص عند إساءة الاستخدام أو مخالفة هذه الشروط.'),
  LegalSection('٥. الاستخدام المحظور',
      '• التحايل على القيود أو الترخيص أو أمان التطبيق، أو الهندسة العكسية أو نسخ التطبيق.\n• إرسال طلبات مكثفة أو أي عمل يعطّل الخدمة عن الآخرين.\n• إساءة استخدام التقييم أو تسجيل مواعيد مزيفة.\n• وضع محتوى مسيء أو مضلل أو مخالف للقانون في الأسماء أو الوصف أو الصور أو الرسائل.'),
  LegalSection('٦. توفر الخدمة',
      'تعمل الخدمة على بنية Google التحتية، وقد تكون أحيانًا بطيئة أو محدودة أو منقطعة (بما في ذلك بسبب قيود الإنترنت). لا نضمن عملها دون انقطاع. ننصح بتدوين المواعيد المهمة في مكان آخر أيضًا.'),
  LegalSection('٧. حدود المسؤولية',
      'بالقدر الذي يسمح به القانون، لا يتحمل المطوّر المسؤولية عن الأضرار غير المباشرة أو فقدان الدخل أو المواعيد أو الخلافات بين الزبون والصالون أو المشكلات الناتجة عن انقطاع الإنترنت أو خدمات الأطراف الثالثة. يُقدَّم التطبيق «كما هو».'),
  LegalSection('٨. التعديل وإنهاء الاستخدام',
      'قد تتغير هذه الشروط وسنطلب موافقتك مجددًا عند التغييرات المهمة. وعند مخالفتها يجوز تقييد وصولك.'),
];
