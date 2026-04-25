using ApartmanApp.Core.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace ApartmanApp.Data.Interceptors;

/// SaveChanges sırasında IAuditable.CreatedAt/UpdatedAt'i otomatik set eder;
/// ISoftDeletable entity'lerde Delete operasyonunu IsDeleted=true'ya çevirir.
public class AuditSaveChangesInterceptor : SaveChangesInterceptor
{
    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        UpdateEntities(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        UpdateEntities(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private static void UpdateEntities(DbContext? context)
    {
        if (context is null) return;

        var now = DateTime.UtcNow;

        foreach (var entry in context.ChangeTracker.Entries())
        {
            // Audit
            if (entry.Entity is IAuditable auditable)
            {
                if (entry.State == EntityState.Added)
                    auditable.CreatedAt = now;
                else if (entry.State == EntityState.Modified)
                    auditable.UpdatedAt = now;
            }

            // Soft delete: Delete state'i Modified'a çevir, IsDeleted=true ata
            if (entry.Entity is ISoftDeletable soft && entry.State == EntityState.Deleted)
            {
                entry.State = EntityState.Modified;
                soft.IsDeleted = true;
                soft.DeletedAt = now;
            }
        }
    }
}
