using ApartmanApp.Business.DTOs.Bina;
using ApartmanApp.Core.Common;
using ApartmanApp.Core.Entities;

namespace ApartmanApp.Business.Services.Abstract;

public interface IBlokService
{
    Task<Result<List<Blok>>> GetAllAsync();
    Task<Result<List<BlokDetayDto>>> GetAllWithSakinlerAsync();
    Task<Result<Blok>> CreateAsync(string ad);
    Task<Result> DeleteAsync(int id);
}
