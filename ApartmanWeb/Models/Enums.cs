using System.Text.Json.Serialization;

namespace ApartmanWeb.Models;

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum KullaniciRol { Admin, Sakin }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum ArizaDurum { Beklemede, Inceleniyor, Tamamlandi, Reddedildi }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum ArizaOncelik { Dusuk, Orta, Yuksek, Kritik }

[JsonConverter(typeof(JsonStringEnumConverter))]
public enum OdemeDurumu { Beklemede, Odendi, Gecikti }
