using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class BildirimlerController : Controller
{
    private readonly IApiService _apiService;

    public BildirimlerController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var bildirimTask = _apiService.GetAsync<ApiResult<List<BildirimDto>>>("/api/bildirim");
            var blokTask = _apiService.GetAsync<ApiResult<List<BlokDto>>>("/api/blok/detay");
            await Task.WhenAll(bildirimTask, blokTask);

            ViewBag.Bloklar = blokTask.Result?.Data ?? new List<BlokDto>();
            return View(bildirimTask.Result?.Data ?? new List<BildirimDto>());
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> TumuOkundu()
    {
        try
        {
            await _apiService.PatchAsync<object>("/api/bildirim/tumu-okundu");
            return Json(new { success = true });
        }
        catch (UnauthorizedAccessException)
        {
            return Json(new { success = false, message = "Oturum süresi doldu." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> OkunduIsaretle(int id)
    {
        try
        {
            await _apiService.PatchAsync<object>($"/api/bildirim/{id}/okundu");
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
    public async Task<IActionResult> Duyuru([FromBody] DuyuruRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/bildirim/duyuru", request);
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
    public async Task<IActionResult> BlokBildirim([FromBody] BlokBildirimRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/bildirim/blok", request);
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
    public async Task<IActionResult> DaireBildirim([FromBody] DaireBildirimRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>("/api/bildirim/daire", request);
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
