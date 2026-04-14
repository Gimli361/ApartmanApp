using ApartmanApp.Business.Services.Abstract;
using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;

namespace ApartmanApp.Business.Services.Concrete;

public class FcmService(ILogger<FcmService> logger) : IFcmService
{
    public async Task SendAsync(string? fcmToken, string baslik, string icerik)
    {
        if (string.IsNullOrWhiteSpace(fcmToken))
            return;

        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new Notification
                {
                    Title = baslik,
                    Body = icerik,
                },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = "apartman_channel",
                        Sound = "default",
                    },
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps { Sound = "default" },
                },
            };

            await FirebaseMessaging.DefaultInstance.SendAsync(message);
        }
        catch (Exception ex)
        {
            // FCM hatası ana işlemi durdurmasın
            logger.LogWarning("FCM gönderim hatası: {Error}", ex.Message);
        }
    }
}
