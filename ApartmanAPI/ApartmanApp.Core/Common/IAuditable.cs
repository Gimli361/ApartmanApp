namespace ApartmanApp.Core.Common;

/// Otomatik CreatedAt/UpdatedAt için. Interceptor SaveChanges sırasında set eder.
public interface IAuditable
{
    DateTime CreatedAt { get; set; }
    DateTime? UpdatedAt { get; set; }
}

/// Soft delete için. SaveChanges sırasında interceptor IsDeleted=true ve DeletedAt'i set eder.
/// AppDbContext bu entity'lere global query filter uygular (IsDeleted=false).
public interface ISoftDeletable
{
    bool IsDeleted { get; set; }
    DateTime? DeletedAt { get; set; }
}
