using ApartmanApp.Business.DTOs.Ariza;
using FluentValidation;

namespace ApartmanApp.Business.Validators;

public class ArizaCreateValidator : AbstractValidator<ArizaCreateDto>
{
    public ArizaCreateValidator()
    {
        RuleFor(x => x.Baslik)
            .NotEmpty().WithMessage("Başlık boş olamaz.")
            .MaximumLength(100).WithMessage("Başlık en fazla 100 karakter olabilir.");

        RuleFor(x => x.Aciklama)
            .NotEmpty().WithMessage("Açıklama boş olamaz.")
            .MaximumLength(1000).WithMessage("Açıklama en fazla 1000 karakter olabilir.");

        RuleFor(x => x.BildirenId)
            .GreaterThan(0).WithMessage("Geçerli bir bildiren kullanıcı ID girilmelidir.");

        RuleFor(x => x.Oncelik)
            .IsInEnum().WithMessage("Geçersiz öncelik değeri.");
    }
}
