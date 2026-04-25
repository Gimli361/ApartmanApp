using ApartmanWeb.Filters;
using ApartmanWeb.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews(options =>
{
    // Tüm POST/PUT/DELETE/PATCH action'lar için otomatik CSRF doğrulaması
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
    // API'den 401 → Login sayfasına yönlendir (token expired auto-logout)
    options.Filters.Add<ApiUnauthorizedFilter>();
});
builder.Services.AddAntiforgery(options =>
{
    // JS fetch ile bu header üzerinden token gönderilir
    options.HeaderName = "RequestVerificationToken";
});
builder.Services.AddHttpContextAccessor();

var apiBaseUrl = builder.Configuration["ApiBaseUrl"] ?? "http://localhost:5255";
builder.Services.AddHttpClient<IApiService, ApiService>(client =>
{
    client.BaseAddress = new Uri(apiBaseUrl);
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Reverse proxy arkasında doğru scheme/host (X-Forwarded-Proto: https) için
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

var isProduction = !builder.Environment.IsDevelopment();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Strict;
        // Production'da cookie sadece HTTPS üzerinden gönderilir
        options.Cookie.SecurePolicy = isProduction
            ? CookieSecurePolicy.Always
            : CookieSecurePolicy.SameAsRequest;
    });

var app = builder.Build();

// ForwardedHeaders auth'tan ÖNCE
app.UseForwardedHeaders();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
