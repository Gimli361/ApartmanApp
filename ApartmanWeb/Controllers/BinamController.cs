using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

[Authorize]
public class BinamController(IApiService apiService) : Controller
{
    public async Task<IActionResult> Index()
    {
        try
        {
            var result = await apiService.GetAsync<ApiResult<List<BlokDto>>>("/api/blok/detay");
            return View(result?.Data ?? new List<BlokDto>());
        }
        catch (UnauthorizedAccessException)
        {
            return RedirectToAction("Login", "Account");
        }
    }

    [HttpPost]
    public async Task<IActionResult> BlokEkle([FromBody] BlokEkleRequest request)
    {
        try
        {
            await apiService.PostAsync<object>("/api/blok", request);
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

    [HttpDelete]
    public async Task<IActionResult> BlokSil(int id)
    {
        try
        {
            await apiService.DeleteAsync($"/api/blok/{id}");
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
    public async Task<IActionResult> DaireEkle([FromBody] DaireEkleRequest request)
    {
        try
        {
            var result = await apiService.PostAsync<ApiResult<DaireDto>>("/api/daire", request);
            return Json(new { success = true, daireId = result?.Data?.Id ?? 0 });
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

    [HttpDelete]
    public async Task<IActionResult> DaireSil(int id)
    {
        try
        {
            await apiService.DeleteAsync($"/api/daire/{id}");
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
