using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class AidatlarController : Controller
{
    private readonly IApiService _apiService;

    public AidatlarController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index(int page = 1, int pageSize = 20)
    {
        try
        {
            var aidatlarTask = _apiService.GetAsync<ApiResult<PagedResult<AidatDto>>>(
                $"/api/aidat/paged?page={page}&pageSize={pageSize}");
            var otomatikTask = _apiService.GetAsync<ApiResult<List<OtomatikAidatDto>>>("/api/otomatik-aidat");
            var kullanicilarTask = _apiService.GetAsync<KullaniciListResponse>("/api/kullanici");

            await Task.WhenAll(aidatlarTask, otomatikTask, kullanicilarTask);

            var paged = aidatlarTask.Result?.Data ?? new PagedResult<AidatDto>
            {
                Page = page,
                PageSize = pageSize
            };

            var model = new AidatViewModel
            {
                Aidatlar = paged.Items,
                AidatSayfa = paged,
                OtomatikAidatlar = otomatikTask.Result?.Data ?? new List<OtomatikAidatDto>(),
                Kullanicilar = kullanicilarTask.Result?.Data ?? new List<KullaniciDto>()
            };

            return View(model);
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> Ekle([FromBody] AidatCreateRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/aidat", request);
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

    [HttpPost]
    public async Task<IActionResult> DurumGuncelle(int id, [FromBody] object durumData)
    {
        try
        {
            await _apiService.PatchAsync<object>($"/api/aidat/{id}/odemeDurumu", durumData);
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
            await _apiService.DeleteAsync($"/api/aidat/{id}");
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

    [HttpPost]
    public async Task<IActionResult> OtomatikEkle([FromBody] OtomatikAidatCreateRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/otomatik-aidat", request);
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

    [HttpPost]
    public async Task<IActionResult> OtomatikToggle(int id)
    {
        try
        {
            await _apiService.PatchAsync<object>($"/api/otomatik-aidat/{id}/toggle");
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

    [HttpPost]
    public async Task<IActionResult> BuAyiOlustur([FromBody] object data)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/otomatik-aidat/uret", data);
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
    public async Task<IActionResult> OtomatikSil(int id)
    {
        try
        {
            await _apiService.DeleteAsync($"/api/otomatik-aidat/{id}");
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
