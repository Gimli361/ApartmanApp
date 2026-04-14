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

    private void SetAuthHeader()
    {
        var token = _httpContextAccessor.HttpContext?.Request.Cookies["jwt_token"];
        if (!string.IsNullOrEmpty(token))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }

    public async Task<T?> GetAsync<T>(string endpoint)
    {
        SetAuthHeader();
        var response = await _httpClient.GetAsync(endpoint);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(content, JsonOptions);
    }

    public async Task<T?> PostAsync<T>(string endpoint, object? data = null)
    {
        SetAuthHeader();
        var json = data != null ? JsonSerializer.Serialize(data, JsonOptions) : "{}";
        var httpContent = new StringContent(json, Encoding.UTF8, "application/json");
        var response = await _httpClient.PostAsync(endpoint, httpContent);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        var responseContent = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"API Error: {response.StatusCode} - {responseContent}");
        }
        return JsonSerializer.Deserialize<T>(responseContent, JsonOptions);
    }

    public async Task<T?> PutAsync<T>(string endpoint, object data)
    {
        SetAuthHeader();
        var json = JsonSerializer.Serialize(data, JsonOptions);
        var httpContent = new StringContent(json, Encoding.UTF8, "application/json");
        var response = await _httpClient.PutAsync(endpoint, httpContent);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        var responseContent = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"API Error: {response.StatusCode} - {responseContent}");
        }
        return JsonSerializer.Deserialize<T>(responseContent, JsonOptions);
    }

    public async Task<T?> PatchAsync<T>(string endpoint, object? data = null)
    {
        SetAuthHeader();
        var json = data != null ? JsonSerializer.Serialize(data, JsonOptions) : "{}";
        var httpContent = new StringContent(json, Encoding.UTF8, "application/json");
        var request = new HttpRequestMessage(HttpMethod.Patch, endpoint) { Content = httpContent };
        var response = await _httpClient.SendAsync(request);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        var responseContent = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpRequestException($"API Error: {response.StatusCode} - {responseContent}");
        }
        return JsonSerializer.Deserialize<T>(responseContent, JsonOptions);
    }

    public async Task<bool> DeleteAsync(string endpoint)
    {
        SetAuthHeader();
        var response = await _httpClient.DeleteAsync(endpoint);
        if (response.StatusCode == System.Net.HttpStatusCode.Unauthorized)
            throw new UnauthorizedAccessException();
        return response.IsSuccessStatusCode;
    }
}
