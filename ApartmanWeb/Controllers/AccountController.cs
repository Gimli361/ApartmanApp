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
    public IActionResult Login(bool expired = false, string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Home");

        var vm = new LoginViewModel();
        if (expired)
            vm.ErrorMessage = "Oturum süreniz doldu. Lütfen tekrar giriş yapın.";
        ViewData["ReturnUrl"] = returnUrl;
        return View(vm);
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

            // Store JWT in cookie. Production'da daima HTTPS şartı.
            var isProd = !HttpContext.RequestServices
                .GetRequiredService<IWebHostEnvironment>().IsDevelopment();
            Response.Cookies.Append("jwt_token", response.Data.Token, new CookieOptions
            {
                HttpOnly = true,
                Expires = DateTimeOffset.UtcNow.AddHours(8),
                SameSite = SameSiteMode.Strict,
                Secure = isProd || Request.IsHttps,
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
        catch (UnauthorizedAccessException)
        {
            model.ErrorMessage = "Email veya şifre hatalı.";
            return View(model);
        }
        catch (HttpRequestException ex) when (
            ex.InnerException is System.Net.Sockets.SocketException ||
            ex.InnerException is System.IO.IOException)
        {
            model.ErrorMessage = "API sunucusuna bağlanılamadı. API'nin çalıştığından emin olun (http://localhost:5255).";
            return View(model);
        }
        catch (TaskCanceledException)
        {
            model.ErrorMessage = "Bağlantı zaman aşımına uğradı. API sunucusunu kontrol edin.";
            return View(model);
        }
        catch (HttpRequestException ex)
        {
            model.ErrorMessage = $"Sunucu hatası: {ex.Message}";
            return View(model);
        }
        catch (Exception ex)
        {
            model.ErrorMessage = $"Beklenmeyen hata: {ex.Message}";
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
