using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;

namespace ApartmanApp.Business.Services.Abstract;

public interface IDaireService
{
    Task<Result<List<Daire>>> GetByBlokAsync(int blokId);
    Task<Result<Daire>> CreateAsync(int blokId, string daireNo);
    Task<Result> DeleteAsync(int id);
}
