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

        // Sonrasında her gece 02:00'de tekrar çalış
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.Now;
            var nextRun = DateTime.Today.AddDays(1).AddHours(2); // yarın 02:00
            var delay = nextRun - now;
            if (delay <= TimeSpan.Zero)
                delay = TimeSpan.FromHours(24);

            logger.LogInformation("Bir sonraki otomatik aidat üretimi: {NextRun}", nextRun);

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

            var now = DateTime.Now;
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
