// Standart kütüphane
#import <Foundation/Foundation.h>

// USB ve Donanım erişimi için gerekli (MTPBridge bunu kullanacak)
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>

/* NOT: libmtp kütüphanesini kullanmak için başlık dosyasını buraya eklemelisin.
 Eğer 'libmtp.h' dosyasını projene sürükleyip bıraktıysan şöyle aç:
*/
// #include "libmtp.h"

/* Eğer Homebrew ile kurduysan (<libmtp.h> bulunamadı derse) şimdilik
 üstteki satırı yorum satırı (//) olarak bırak. Önce IOKit ile cihazı görelim.
*/
