using System.Security.Claims;
using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class ArizalarController : Controller
{
    private readonly IApiService _apiService;

    public ArizalarController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var result = await _apiService.GetAsync<ApiResult<List<ArizaDto>>>("/api/ariza");
            return View(result?.Data ?? new List<ArizaDto>());
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    public async Task<IActionResult> Detay(int id)
    {
        try
        {
            var arizaTask = _apiService.GetAsync<ApiResult<ArizaDto>>($"/api/ariza/{id}");
            var fotoTask = _apiService.GetAsync<ApiResult<List<ArizaFotoDto>>>($"/api/ariza/{id}/foto");

            await Task.WhenAll(arizaTask, fotoTask);

            var model = new ArizaDetayViewModel
            {
                Ariza = arizaTask.Result?.Data ?? new ArizaDto(),
                Fotograflar = fotoTask.Result?.Data ?? new List<ArizaFotoDto>()
            };

            return View(model);
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
        catch
        {
            return RedirectToAction("Index");
        }
    }

    [HttpPost]
    public async Task<IActionResult> Ekle([FromBody] ArizaCreateRequest request)
    {
        try
        {
            var kullaniciIdStr = User.FindFirstValue("KullaniciId");
            if (!int.TryParse(kullaniciIdStr, out var kullaniciId) || kullaniciId == 0)
                return Json(new { success = false, message = "Oturum bilgisi alınamadı. Lütfen tekrar giriş yapın." });

            request.BildirenId = kullaniciId;
            await _apiService.PostAsync<object>("/api/ariza", request);
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum süreniz doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> DurumGuncelle(int id, [FromBody] object durumData)
    {
        try
        {
            await _apiService.PatchAsync<object>($"/api/ariza/{id}/durum", durumData);
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum süreniz doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }

    [HttpDelete]
    public async Task<IActionResult> Sil(int id)
    {
        try
        {
            await _apiService.DeleteAsync($"/api/ariza/{id}");
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum süreniz doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }
}
