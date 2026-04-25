using ApartmanApp.Core.Common;
using Microsoft.EntityFrameworkCore;

namespace ApartmanApp.Data.Extensions;

public static class PagingExtensions
{
    /// IQueryable'ı sayfalı sonuca çevirir. Tek bir COUNT + Skip/Take sorgusu üretir.
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(
        this IQueryable<T> query,
        int page,
        int pageSize,
        CancellationToken ct = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;

        var total = await query.CountAsync(ct);
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return new PagedResult<T>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = total
        };
    }
}
