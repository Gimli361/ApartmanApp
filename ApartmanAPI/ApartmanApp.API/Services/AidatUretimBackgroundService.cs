using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Data.Context;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.API.Services;

/// Her gece çalışarak aktif otomatik aidat konfigürasyonlarından
/// o ay için eksik kayıtları oluşturur.
public class AidatUretimBackgroundService(
    IServiceScopeFactory scopeFactory,
    ILogger<AidatUretimBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Uygulama ayağa kalktığında hemen bir kez çalıştır
        await UretAsync(stoppingToken);

        // Sonrasında her gece 02:00 UTC'de tekrar çalış
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            var nextRun = new DateTime(now.Year, now.Month, now.Day, 2, 0, 0, DateTimeKind.Utc)
                .AddDays(1);
            var delay = nextRun - now;
            if (delay <= TimeSpan.Zero)
                delay = TimeSpan.FromHours(24);

            logger.LogInformation("Bir sonraki otomatik aidat üretimi: {NextRun} UTC", nextRun);

            await Task.Delay(delay, stoppingToken);
            await UretAsync(stoppingToken);
        }
    }

    private async Task UretAsync(CancellationToken ct)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var service = scope.ServiceProvider.GetRequiredService<IOtomatikAidatService>();

            var now = DateTime.UtcNow;
            var uretilen = await service.UretAylikAidatlarAsync(now.Month, now.Year);

            if (uretilen > 0)
                logger.LogInformation("Otomatik aidat üretimi: {Sayi} kayıt oluşturuldu.", uretilen);
        }
        catch (Exception ex) when (!ct.IsCancellationRequested)
        {
            logger.LogError(ex, "Otomatik aidat üretimi sırasında hata oluştu.");
        }
    }
}
