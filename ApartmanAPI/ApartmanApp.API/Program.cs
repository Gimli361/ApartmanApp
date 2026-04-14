using System.Text;
using ApartmanApp.API.Services;
using ApartmanApp.Business.Mappings;
using ApartmanApp.Business.Services.Abstract;
using ApartmanApp.Business.Services.Concrete;
using ApartmanApp.Data.Context;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Firebase Admin SDK
var firebaseCredPath = Path.Combine(builder.Environment.ContentRootPath,
    "apartmanapp-af9a4-firebase-adminsdk-fbsvc-55b7ce41ce.json");
FirebaseApp.Create(new AppOptions
{
    Credential = GoogleCredential.FromFile(firebaseCredPath),
});

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

// AutoMapper
builder.Services.AddAutoMapper(typeof(MappingProfile));

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

builder.Services.AddControllers()
    .AddJsonOptions(opt =>
    {
        opt.JsonSerializerOptions.PropertyNamingPolicy =
            System.Text.Json.JsonNamingPolicy.CamelCase;
        opt.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
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

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// wwwroot/uploads klasörünü başlangıçta oluştur (Faz 5 fix)
var uploadsPath = Path.Combine(app.Environment.WebRootPath ?? "wwwroot", "uploads");
Directory.CreateDirectory(uploadsPath);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
