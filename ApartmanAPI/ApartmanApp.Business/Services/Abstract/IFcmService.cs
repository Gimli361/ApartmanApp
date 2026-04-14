namespace ApartmanApp.Business.Services.Abstract;

public interface IFcmService
{
    /// Tek bir FCM token'a bildirim gönderir. Token null/boşsa sessizce atlar.
    Task SendAsync(string? fcmToken, string baslik, string icerik);
}
