import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mi_billetera_digital/app_theme.dart';

class AccountLogoWidget extends StatelessWidget {
  final String accountName;
  final double size;

  const AccountLogoWidget({
    super.key,
    required this.accountName,
    this.size = 30.0, required iconPath,
  });

  // Widget interno para manejar logos con padding
  Widget _buildPaddedLogo(Widget logo) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(
        2.0,
      ), // Un pequeño relleno para que no toquen los bordes
      child: logo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowerCaseName = accountName.toLowerCase();

    final Map<String, String> logoMap = {
      'mercado pago':
          'https://imgs.search.brave.com/seDJmrt4BBMVhgknj2kramEXYbV2ql09OXw0P4WxSEA/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly92ZWN0/b3JzZWVrLmNvbS93/cC1jb250ZW50L3Vw/bG9hZHMvMjAyMy8w/OC9NZXJjYWRvLVBh/Z28tSWNvbi1Mb2dv/LVZlY3Rvci5zdmct/LnBuZw',
      'ualá': 'https://developers.ualabis.com.ar/logo-large.png',
      'naranja x':
          'https://static.wikia.nocookie.net/logopedia/images/e/eb/Tarjeta-naranja.svg/revision/latest/scale-to-width-down/1200?cb=20210820182028',
      'brubank':
          'https://s3.amazonaws.com/blab-impact-published-production/PgKSqf7GflEAv6IXJttPH2zJkGY1bUcK',
      'banco galicia':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREN_rfEjV-HuzxAiC5tmQTrQmIQfnnLA3P3A&s',
      'banco nación':
          'https://www.santafe.gob.ar/ofertaexportable/uploads/empresas/logos/d7d4c-12791044_1116004598423586_3146263889162601579_n.jpg',
      'santander':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoKfHzkQVEUhXiB7hq52BKJy_X1qcv2lRCBg&s',
      'bbva':
          'https://logos-world.net/wp-content/uploads/2021/02/BBVA-Logo.png',
      'banco macro':
          'https://companieslogo.com/img/orig/BMA-99c2b89d.png?t=1720244491',
      'banco provincia':
          'https://yt3.googleusercontent.com/RyDwonK_uwuFwh7W3l4c1o6dWBrWVsctptL87rL13wcPe3N0avPYXBHKUOIjmXOwyu5XQZdmwQ=s900-c-k-c0x00ffffff-no-rj', // Asegúrate de reemplazar esta URL
      'icbc':
          'https://images.seeklogo.com/logo-png/6/1/icbc-logo-png_seeklogo-69449.png',
      'hsbc':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/HSBC_%E6%BB%99%E8%B1%90_%28logo_only%29.svg/1200px-HSBC_%E6%BB%99%E8%B1%90_%28logo_only%29.svg.png',
      'banco ciudad':
          'https://pbs.twimg.com/profile_images/985870544460447746/WlgdUFc0_400x400.jpg',
      'banco patagonia':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQvf0OXwPjL9AHDNHyv7xOhe9Yv60Am4I-vmg&s',
      'banco credicoop':
          'https://sme.com.ar/wp-content/uploads/2023/08/credicoop-1.png',
      'banco comafi':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRsLfBJ_fnRr3z3xvGdXREa-jrTVonWK4r5lw&s',
      'banco hipotecario':
          'https://hiringroomcampus.com/assets/media/ucaecono/company_abd38aa9f9e9298b0b7fa4ab0571cbbb.jpg',
    };

    String? logoUrl;
    for (var key in logoMap.keys) {
      if (lowerCaseName.contains(key)) {
        logoUrl = logoMap[key];
        break;
      }
    }

    if (logoUrl != null) {
      if (logoUrl.endsWith('.svg')) {
        return _buildPaddedLogo(
          SvgPicture.network(
            logoUrl,
            placeholderBuilder: (context) => Icon(
              Icons.account_balance,
              size: size,
              color: Colors.grey[300],
            ),
          ),
        );
      } else {
        return _buildPaddedLogo(
          Image.network(
            logoUrl,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.account_balance, size: size),
          ),
        );
      }
    }

    if (lowerCaseName.contains('banco')) {
      return Icon(
        Icons.account_balance,
        size: size,
        color: AppTheme.primaryColor,
      );
    } else if (lowerCaseName.contains('efectivo')) {
      return Icon(Icons.money, size: size, color: AppTheme.accentColor);
    }

    return Icon(Icons.credit_card, size: size, color: AppTheme.subtextColor);
  }
}
