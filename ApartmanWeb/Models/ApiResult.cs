namespace ApartmanWeb.Models;

/// API'nin Result<T> wrapper'ını karşılar.
public class ApiResult<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public List<string> Errors { get; set; } = new();
}
