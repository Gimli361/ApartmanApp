using System.Text;
using System.Threading.RateLimiting;
using ApartmanApp.API.Middleware;
using ApartmanApp.API.Services;
using ApartmanApp.Business.Mappings;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Services.Concrete;
using ApartmanApp.Data.Context;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Sentry — hata izleme. DSN appsettings/env'den okunur; boşsa Sentry pasif çalışır.
var sentryDsn = builder.Configuration["Sentry:Dsn"];
if (!string.IsNullOrWhiteSpace(sentryDsn))
{
    builder.WebHost.UseSentry(o =>
    {
        o.Dsn = sentryDsn;
        o.Environment = builder.Environment.EnvironmentName;
        o.TracesSampleRate = builder.Environment.IsDevelopment() ? 1.0 : 0.2;
        o.SendDefaultPii = false;
        o.AttachStacktrace = true;
        // 4xx istekleri Sentry'ye gönderme (404 spam'i önler)
        o.MinimumEventLevel = Microsoft.Extensions.Logging.LogLevel.Error;
    });
}

// Serilog — console + günlük dönüşlü dosya (logs/api-YYYYMMDD.log, 14 gün tut)
builder.Host.UseSerilog((ctx, services, cfg) => cfg
    .ReadFrom.Configuration(ctx.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(
        path: Path.Combine(ctx.HostingEnvironment.ContentRootPath, "logs", "api-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {SourceContext} {Message:lj}{NewLine}{Exception}"));

// Firebase Admin SDK
var firebaseCredPath = Path.Combine(builder.Environment.ContentRootPath,
    "apartmanapp-af9a4-firebase-adminsdk-fbsvc-55b7ce41ce.json");
FirebaseApp.Create(new AppOptions
{
    Credential = CredentialFactory.FromFile(firebaseCredPath, "service_account"),
});

// DbContext + audit/soft-delete interceptor
builder.Services.AddSingleton<ApartmanApp.Data.Interceptors.AuditSaveChangesInterceptor>();
builder.Services.AddDbContext<AppDbContext>((sp, options) =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default"));
    options.AddInterceptors(sp.GetRequiredService<ApartmanApp.Data.Interceptors.AuditSaveChangesInterceptor>());
});

// AutoMapper
builder.Services.AddAutoMapper(cfg => cfg.AddProfile<MappingProfile>());

// Services
builder.Services.AddScoped<IArizaService, ArizaService>();
builder.Services.AddScoped<IKullaniciService, KullaniciService>();
builder.Services.AddScoped<IFotoService, FotoService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IBildirimService, BildirimService>();
builder.Services.AddScoped<IFcmService, FcmService>();
builder.Services.AddScoped<IAidatService, AidatService>();
builder.Services.AddScoped<IOtomatikAidatService, OtomatikAidatService>();
builder.Services.AddScoped<IArizaTakipService, ArizaTakipService>();
builder.Services.AddScoped<IBlokService, BlokService>();
builder.Services.AddScoped<IDaireService, DaireService>();
builder.Services.AddScoped<IOylamaService, OylamaService>();
builder.Services.AddHostedService<AidatUretimBackgroundService>();
builder.Services.AddHttpContextAccessor();

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        };
    });

builder.Services.AddAuthorization();

// Rate limiting — login brute-force koruması (IP başına 5 dk'da 10 istek)
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("login", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(5),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
});

builder.Services.AddControllers()
    .AddJsonOptions(opt =>
    {
        opt.JsonSerializerOptions.PropertyNamingPolicy =
            System.Text.Json.JsonNamingPolicy.CamelCase;
        opt.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
        opt.JsonSerializerOptions.ReferenceHandler =
            System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "ApartmanApp API", Version = "v1" });

    // Swagger'a JWT desteği
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Bearer token. Örnek: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Reverse proxy (Nginx/Caddy/Cloudflare) arkasında çalışırken
// gerçek istemci IP'sini ve HTTPS scheme'ini görmek için.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});

builder.Services.AddCors(options =>
{
    var allowedOrigins = builder.Configuration
        .GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    options.AddDefaultPolicy(policy =>
    {
        if (allowedOrigins.Length == 0)
        {
            // Geliştirme fallback'i — production'da Cors:AllowedOrigins set edilmeli
            policy.SetIsOriginAllowed(_ => builder.Environment.IsDevelopment())
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

var app = builder.Build();

// Bekleyen migration'ları uygula
using (var scope = app.Services.CreateScope())
{
    var db2 = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db2.Database.Migrate();
}

// wwwroot/uploads klasörünü başlangıçta oluştur (Faz 5 fix)
var uploadsPath = Path.Combine(app.Environment.WebRootPath ?? "wwwroot", "uploads");
Directory.CreateDirectory(uploadsPath);

// ÖNEMLİ: ForwardedHeaders auth/HTTPS redirect'ten ÖNCE gelmeli;
// reverse proxy arkasında scheme/host doğru çözülsün diye.
app.UseForwardedHeaders();

// Production: HTTPS zorunlu + HSTS (1 yıl, alt domain dahil)
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

// Global exception handler — pipeline'ın en başında
app.UseMiddleware<GlobalExceptionMiddleware>();

// HTTP request logging (Serilog) — yöntem, path, status, süre
app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseStaticFiles();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
// Admin seed — yalnızca admin kullanıcısı yoksa oluştur (mevcut admin'in şifresine dokunulmaz).
// Acil reset gerekirse `AdminSeed:ForcePasswordReset=true` ile bir kez çalıştırıp tekrar false'a çekin.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var adminEmail = app.Configuration["AdminSeed:Email"]
        ?? throw new InvalidOperationException("AdminSeed:Email yapılandırılmamış.");
    var adminSifre = app.Configuration["AdminSeed:Sifre"]
        ?? throw new InvalidOperationException("AdminSeed:Sifre yapılandırılmamış.");
    var forceReset = app.Configuration.GetValue("AdminSeed:ForcePasswordReset", false);

    var admin = db.Kullanicilar
        .FirstOrDefault(k => k.Email.ToLower() == adminEmail.ToLower());

    if (admin is null)
    {
        db.Kullanicilar.Add(new ApartmanApp.Core.Entities.Kullanici
        {
            Ad = "Admin",
            Soyad = "Kullanıcı",
            Email = adminEmail,
            Rol = ApartmanApp.Core.Enums.KullaniciRol.Admin,
            DaireNo = "",
            SifreHash = BCrypt.Net.BCrypt.HashPassword(adminSifre),
        });
        db.SaveChanges();
        Console.WriteLine("[Seed] Admin kullanıcısı oluşturuldu.");
    }
    else if (forceReset)
    {
        admin.SifreHash = BCrypt.Net.BCrypt.HashPassword(adminSifre);
        admin.Rol = ApartmanApp.Core.Enums.KullaniciRol.Admin;
        db.SaveChanges();
        Console.WriteLine("[Seed] Admin şifresi config ile zorla sıfırlandı (ForcePasswordReset=true).");
    }
}

app.Run();
