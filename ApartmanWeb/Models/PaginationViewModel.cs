namespace ApartmanWeb.Models;

/// _Pagination.cshtml partial view'i için.
public class PaginationViewModel
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages { get; set; }
    /// Sayfa numarası verince hedef URL döndüren delegate. Controller'da set edilir.
    public Func<int, string> UrlFor { get; set; } = _ => "#";

    public static PaginationViewModel? FromPaged<T>(PagedResult<T>? paged, Func<int, string> urlFor)
    {
        if (paged is null) return null;
        return new PaginationViewModel
        {
            Page = paged.Page,
            PageSize = paged.PageSize,
            TotalCount = paged.TotalCount,
            TotalPages = paged.TotalPages,
            UrlFor = urlFor
        };
    }
}
