using System.Net;
using System.Text.Json;

namespace ApartmanApp.API.Middleware;

public class GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
{
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            var traceId = context.TraceIdentifier;
            logger.LogError(ex,
                "Beklenmedik hata. TraceId={TraceId} Path={Path} Method={Method} User={User}",
                traceId,
                context.Request.Path,
                context.Request.Method,
                context.User?.Identity?.Name ?? "anonim");

            context.Response.ContentType = "application/problem+json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

            var payload = new
            {
                type = "https://tools.ietf.org/html/rfc7231#section-6.6.1",
                title = "Sunucu hatası",
                status = 500,
                detail = "Beklenmeyen bir hata oluştu. Sorun devam ederse yöneticiye traceId iletin.",
                traceId
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(payload, JsonOpts));
        }
    }
}
