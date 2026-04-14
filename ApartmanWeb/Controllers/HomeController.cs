using System.Diagnostics;
using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly IApiService _apiService;

    public HomeController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var kullanicilarTask = _apiService.GetAsync<KullaniciListResponse>("/api/kullanici");
            var arizalarTask = _apiService.GetAsync<ApiResult<List<ArizaDto>>>("/api/ariza");
            var aidatlarTask = _apiService.GetAsync<ApiResult<List<AidatDto>>>("/api/aidat");

            await Task.WhenAll(kullanicilarTask, arizalarTask, aidatlarTask);

            var kullanicilar = kullanicilarTask.Result?.Data ?? new List<KullaniciDto>();
            var arizalar = arizalarTask.Result?.Data ?? new List<ArizaDto>();
            var aidatlar = aidatlarTask.Result?.Data ?? new List<AidatDto>();

            var model = new DashboardViewModel
            {
                ToplamSakin = kullanicilar.Count(k => k.Rol == "Sakin"),
                BekleyenAriza = arizalar.Count(a => a.Durum == "Beklemede"),
                OdenmemisAidat = aidatlar.Count(a => a.OdemeDurumu != "Odendi"),
                KritikAriza = arizalar.Count(a => a.Oncelik == "Kritik"),
                SonArizalar = arizalar.OrderByDescending(a => a.Tarih).Take(5).ToList()
            };

            return View(model);
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
        catch (Exception)
        {
            return View(new DashboardViewModel());
        }
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
