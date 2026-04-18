using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class OylamalarController : Controller
{
    private readonly IApiService _apiService;

    public OylamalarController(IApiService apiService)
    {
        _apiService = apiService;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var result = await _apiService.GetAsync<ApiResult<List<OylamaListDto>>>("/api/oylama");
            return View(result?.Data ?? new List<OylamaListDto>());
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
            var result = await _apiService.GetAsync<ApiResult<OylamaDetailDto>>($"/api/oylama/{id}");
            if (result?.Data is null)
                return RedirectToAction(nameof(Index));
            return View(result.Data);
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> Ekle([FromBody] OylamaCreateRequest request)
    {
        try
        {
            var result = await _apiService.PostAsync<ApiResult<OylamaDetailDto>>("/api/oylama", request);
            if (result?.Success == true)
                return Json(new { success = true, id = result.Data!.Id });
            return Json(new { success = false, message = "Oylama oluşturulamadı." });
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
    public async Task<IActionResult> OyVer(int id, [FromBody] OyVerRequest request)
    {
        try
        {
            await _apiService.PostAsync<object>($"/api/oylama/{id}/oy", request);
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
    public async Task<IActionResult> OyGeriAl(int id)
    {
        try
        {
            await _apiService.DeleteAsync($"/api/oylama/{id}/oy");
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
    public async Task<IActionResult> Toggle(int id)
    {
        try
        {
            await _apiService.PatchAsync<object>($"/api/oylama/{id}/toggle");
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
    public async Task<IActionResult> Sil(int id)
    {
        try
        {
            await _apiService.DeleteAsync($"/api/oylama/{id}");
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
}

public class OyVerRequest
{
    public int SecenekId { get; set; }
}
