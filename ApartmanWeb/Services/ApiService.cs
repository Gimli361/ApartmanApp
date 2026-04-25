using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace ApartmanWeb.Services;

public class ApiService : IApiService
{
    private readonly HttpClient _httpClient;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public ApiService(HttpClient httpClient, IHttpContextAccessor httpContextAccessor)
    {
        _httpClient = httpClient;
        _httpContextAccessor = httpContextAccessor;
    }

    private HttpRequestMessage BuildRequest(HttpMethod method, string endpoint, object? body = null)
    {
        var request = new HttpRequestMessage(method, endpoint);

        var token = _httpContextAccessor.HttpContext?.Request.Cookies["jwt_token"];
        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        if (body is not null || method == HttpMethod.Post || method == HttpMethod.Put || method.Method == "PATCH")
        {
            var json = body != null ? JsonSerializer.Serialize(body, JsonOptions) : "{}";
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        return request;
    }

    private static async Task<string> ReadAndEnsureSuccessAsync(HttpResponseMessage response)
    {
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        var content = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException($"API Error: {response.StatusCode} - {content}");
        return content;
    }

    public async Task<T?> GetAsync<T>(string endpoint)
    {
        using var request = BuildRequest(HttpMethod.Get, endpoint);
        using var response = await _httpClient.SendAsync(request);
        var content = await ReadAndEnsureSuccessAsync(response);
        return JsonSerializer.Deserialize<T>(content, JsonOptions);
    }

    public async Task<T?> PostAsync<T>(string endpoint, object? data = null)
    {
        using var request = BuildRequest(HttpMethod.Post, endpoint, data);
        using var response = await _httpClient.SendAsync(request);
        var content = await ReadAndEnsureSuccessAsync(response);
        return JsonSerializer.Deserialize<T>(content, JsonOptions);
    }

    public async Task<T?> PutAsync<T>(string endpoint, object data)
    {
        using var request = BuildRequest(HttpMethod.Put, endpoint, data);
        using var response = await _httpClient.SendAsync(request);
        var content = await ReadAndEnsureSuccessAsync(response);
        return JsonSerializer.Deserialize<T>(content, JsonOptions);
    }

    public async Task<T?> PatchAsync<T>(string endpoint, object? data = null)
    {
        using var request = BuildRequest(HttpMethod.Patch, endpoint, data);
        using var response = await _httpClient.SendAsync(request);
        var content = await ReadAndEnsureSuccessAsync(response);
        return JsonSerializer.Deserialize<T>(content, JsonOptions);
    }

    public async Task<bool> DeleteAsync(string endpoint)
    {
        using var request = BuildRequest(HttpMethod.Delete, endpoint);
        using var response = await _httpClient.SendAsync(request);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        return response.IsSuccessStatusCode;
    }
}
