using ApartmanApp.Business.DTOs.Ariza;
using ApartmanApp.Core.Common;
using Microsoft.AspNetCore.Http;

namespace ApartmanApp.Business.Services.Abstract;

public interface IFotoService
{
    Task<Result<ArizaFotoDto>> UploadAsync(int arizaId, IFormFile dosya);
    Task<Result<List<ArizaFotoDto>>> GetByArizaIdAsync(int arizaId);
    Task<Result> DeleteAsync(int fotoId);
}
