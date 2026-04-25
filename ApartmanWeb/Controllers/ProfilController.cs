using System.Security.Claims;
using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class ProfilController : Controller
{
    private readonly IApiService _apiService;

    public ProfilController(IApiService apiService)
    {
        _apiService = apiService;
    }

    private int CurrentUserId =>
        int.TryParse(User.FindFirstValue("KullaniciId"), out var id) ? id : 0;

    public async Task<IActionResult> Index()
    {
        try
        {
            var result = await _apiService.GetAsync<ApiResult<KullaniciDto>>("/api/kullanici/me");
            return View(result?.Data ?? new KullaniciDto());
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> BilgiGuncelle([FromBody] ProfilUpdateRequest request)
    {
        try
        {
            if (CurrentUserId == 0)
                return Json(new { success = false, message = "Oturum bilgisi alınamadı." });

            await _apiService.PutAsync<object>($"/api/kullanici/{CurrentUserId}", request);
            return Json(new { success = true, message = "Bilgileriniz güncellendi." });
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
    public async Task<IActionResult> SifreGuncelle([FromBody] SifreGuncelleRequest request)
    {
        try
        {
            if (CurrentUserId == 0)
                return Json(new { success = false, message = "Oturum bilgisi alınamadı." });

            await _apiService.PatchAsync<object>(
                $"/api/kullanici/{CurrentUserId}/sifre", request);
            return Json(new { success = true, message = "Şifreniz güncellendi." });
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
