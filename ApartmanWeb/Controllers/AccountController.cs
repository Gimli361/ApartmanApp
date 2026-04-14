using System.Security.Claims;
using ApartmanWeb.Models;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;

namespace ApartmanWeb.Controllers;

public class AccountController : Controller
{
    private readonly IApiService _apiService;

    public AccountController(IApiService apiService)
    {
        _apiService = apiService;
    }

    [HttpGet]
    public IActionResult Login()
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Home");
        return View(new LoginViewModel());
    }

    [HttpPost]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid)
            return View(model);

        try
        {
            var response = await _apiService.PostAsync<LoginResponse>("/api/auth/login", new LoginRequest
            {
                Email = model.Email,
                Sifre = model.Sifre
            });

            if (response?.Success != true || response.Data?.User == null)
            {
                model.ErrorMessage = response?.Message ?? "Giris basarisiz.";
                return View(model);
            }

            if (response.Data.User.Rol != "Admin")
            {
                model.ErrorMessage = "Bu panel sadece yoneticiler icindir.";
                return View(model);
            }

            // Store JWT in cookie
            Response.Cookies.Append("jwt_token", response.Data.Token, new CookieOptions
            {
                HttpOnly = true,
                Expires = DateTimeOffset.UtcNow.AddHours(8),
                SameSite = SameSiteMode.Lax
            });

            // Create claims for cookie auth
            var claims = new List<Claim>
            {
                new(ClaimTypes.Name, response.Data.User.AdSoyad),
                new(ClaimTypes.Email, response.Data.User.Email),
                new(ClaimTypes.Role, response.Data.User.Rol),
                new("KullaniciId", response.Data.User.Id.ToString())
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

            return RedirectToAction("Index", "Home");
        }
        catch (Exception)
        {
            model.ErrorMessage = "Sunucu ile baglanti kurulamadi.";
            return View(model);
        }
    }

    [HttpPost]
    public async Task<IActionResult> Logout()
    {
        Response.Cookies.Delete("jwt_token");
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Login");
    }
}
