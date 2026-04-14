using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class KullanicilarController : Controller
{
    private readonly IApiService _apiService;

    public KullanicilarController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var response = await _apiService.GetAsync<KullaniciListResponse>("/api/kullanici");
            return View(response?.Data ?? new List<KullaniciDto>());
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> Ekle([FromBody] KullaniciCreateRequest request)
    {
        try
        {
            var response = await _apiService.PostAsync<object>("/api/kullanici", request);
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum suresi doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }

    [HttpPut]
    public async Task<IActionResult> Guncelle(int id, [FromBody] KullaniciUpdateRequest request)
    {
        try
        {
            await _apiService.PutAsync<object>($"/api/kullanici/{id}", request);
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum suresi doldu." });
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
            await _apiService.DeleteAsync($"/api/kullanici/{id}");
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum suresi doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }
}
