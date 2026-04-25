using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace ApartmanWeb.Filters;

/// API'den 401 (UnauthorizedAccessException) gelirse cookie'yi temizler ve
/// Login sayfasına yönlendirir. AJAX istekleri için 401 + JSON döner.
public class ApiUnauthorizedFilter : IAsyncExceptionFilter
{
    public async Task OnExceptionAsync(ExceptionContext context)
    {
        if (context.Exception is not UnauthorizedAccessException)
            return;

        var http = context.HttpContext;

        // Cookie tabanlı auth'tan çıkış (jwt_token cookie + auth cookie)
        await http.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        http.Response.Cookies.Delete("jwt_token");

        var isAjax = http.Request.Headers.XRequestedWith == "XMLHttpRequest"
            || http.Request.Headers.Accept.ToString().Contains("application/json", StringComparison.OrdinalIgnoreCase);

        if (isAjax)
        {
            context.Result = new JsonResult(new
            {
                success = false,
                message = "Oturum süresi doldu. Lütfen tekrar giriş yapın.",
                redirect = "/Account/Login"
            })
            {
                StatusCode = StatusCodes.Status401Unauthorized
            };
        }
        else
        {
            var returnUrl = http.Request.Path + http.Request.QueryString;
            context.Result = new RedirectToActionResult(
                "Login", "Account",
                new { returnUrl, expired = true });
        }

        context.ExceptionHandled = true;
    }
}
