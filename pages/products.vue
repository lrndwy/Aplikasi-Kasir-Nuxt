<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-2 sm:p-4">
    <h1 class="text-2xl sm:text-3xl font-bold mb-4 sm:mb-6 text-gray-900 dark:text-white">
      Manajemen Produk
    </h1>

    <div v-if="pageLoading" class="flex justify-center items-center h-64">
      <div class="spinner"></div>
    </div>

    <div
      v-else-if="!hasAdminOrManagerRole"
      class="text-center text-red-500 dark:text-red-400"
    >
      Anda tidak memiliki izin untuk mengakses halaman ini.
    </div>

    <div v-else>
      <div class="mb-6 flex justify-end">
        <Dialog :open="isProductFormOpen" @update:open="isProductFormOpen = $event">
          <DialogTrigger as-child>
            <Button @click="addNewProduct">Tambah Produk Baru</Button>
          </DialogTrigger>
          <DialogContent class="sm:max-w-[600px] p-6 max-h-[80vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{{
                isEditing ? "Edit Produk" : "Tambah Produk Baru"
              }}</DialogTitle>
              <DialogDescription>
                {{
                  isEditing
                    ? "Perbarui detail produk."
                    : "Tambahkan produk baru ke daftar."
                }}
              </DialogDescription>
            </DialogHeader>
            <form @submit.prevent="saveProduct" class="space-y-6 py-4">
              <div>
                <Label for="productImage" class="mb-2">Gambar Produk</Label>
                <ImageUpload
                  v-model="productForm.imageFile"
                  :initial-image-url="productForm.image_url"
                  @remove="removeImage"
                />
                <div
                  v-if="uploadingImage"
                  class="text-sm text-gray-500 dark:text-gray-400 mt-2"
                >
                  Mengunggah gambar...
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label for="productName" class="mb-2">Nama Produk</Label>
                  <Input
                    id="productName"
                    v-model="productForm.name"
                    type="text"
                    placeholder="Nama Produk"
                    required
                  />
                </div>
                <div>
                  <Label for="productCategory" class="mb-2">Kategori</Label>
                  <Select v-model="productForm.category_id">
                    <SelectTrigger class="w-full">
                      <SelectValue
                        :placeholder="
                          productForm.category_id
                            ? categories.find((c) => c.id === productForm.category_id)?.name
                            : 'Pilih Kategori'
                        "
                      />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem
                        v-for="category in categories"
                        :key="category.id"
                        :value="category.id"
                      >
                        {{ category.name }}
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div>
                <Label for="productDescription" class="mb-2">Deskripsi</Label>
                <Textarea
                  id="productDescription"
                  v-model="productForm.description"
                  placeholder="Deskripsi Produk"
                />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label for="productSku" class="mb-2">SKU</Label>
                  <Input
                    id="productSku"
                    v-model="productForm.sku"
                    type="text"
                    placeholder="SKU Produk"
                  />
                </div>
                <div>
                  <Label for="productBarcode" class="mb-2">Barcode</Label>
                  <Input
                    id="productBarcode"
                    v-model="productForm.barcode"
                    type="text"
                    placeholder="Barcode Produk"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label for="productPrice" class="mb-2">Harga Jual</Label>
                  <Input
                    id="productPrice"
                    v-model.number="productForm.price"
                    type="number"
                    step="0.01"
                    required
                  />
                </div>
                <div>
                  <Label for="productCost" class="mb-2">Harga Pokok</Label>
                  <Input
                    id="productCost"
                    v-model.number="productForm.cost"
                    type="number"
                    step="0.01"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label for="productStock" class="mb-2">Stok</Label>
                  <Input
                    id="productStock"
                    v-model.number="productForm.stock"
                    type="number"
                  />
                </div>
                <div>
                  <Label for="productMinStock" class="mb-2">Stok Minimum</Label>
                  <Input
                    id="productMinStock"
                    v-model.number="productForm.min_stock"
                    type="number"
                  />
                </div>
              </div>

              <div class="flex items-center space-x-2">
                <Checkbox id="productIsActive" v-model="productForm.is_active" />
                <Label for="productIsActive">Aktif</Label>
              </div>
              <DialogFooter class="flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2 pt-4">
                <DialogClose as-child>
                  <Button type="button" variant="outline" @click="cancelEdit"
                    class="w-full sm:w-auto mb-2 sm:mb-0"
                    >Batal</Button
                  >
                </DialogClose>
                <Button
                  v-if="isEditing"
                  type="button"
                  variant="destructive"
                  @click="confirmDeleteProduct(productForm.id)"
                  :disabled="loading"
                  class="w-full sm:w-auto mb-2 sm:mb-0"
                >
                  Hapus Produk
                </Button>
                <Button type="submit" :disabled="loading" class="w-full sm:w-auto">
                  <span v-if="loading">Menyimpan...</span>
                  <span v-else>{{
                    isEditing ? "Perbarui Produk" : "Tambah Produk"
                  }}</span>
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <!-- Daftar Produk -->
        <h2 class="text-xl sm:text-2xl font-semibold mb-3 sm:mb-4 text-gray-900 dark:text-white">
          Daftar Produk
        </h2>
        <div
          v-if="products.length === 0 && !loading"
          class="text-center text-gray-500 dark:text-gray-400 py-8 bg-white dark:bg-gray-800 shadow-md rounded-lg p-4 sm:p-6"
        >
          Tidak ada produk ditemukan.
        </div>
        <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          <Card
            v-for="product in products"
            :key="product.id"
            class="flex cursor-pointer flex-col overflow-hidden rounded-lg border bg-white shadow-sm transition-all hover:shadow-lg dark:border-gray-700 dark:bg-gray-800"
            @click="editProduct(product)"
          >
            <div class="relative">
              <img
                v-if="product.image_url"
                :src="product.image_url"
                alt="Product Image"
                class="aspect-square w-full object-cover -mt-10"
              />
              <div
                v-else
                class="flex aspect-square w-full items-center justify-center bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
              >
                No Image
              </div>
              <div class="absolute right-2 -top-3 flex items-center space-x-2">
                <Badge
                  :class="product.is_active ? ' text-white' : 'bg-red-500 text-white'"
                  class="text-xs"
                >
                  {{ product.is_active ? "Aktif" : "Tidak Aktif" }}
                </Badge>
              </div>
            </div>
            <div class="p-4">
              <h3 class="mb-1 text-lg font-semibold text-gray-900 dark:text-white">
                {{ product.name }}
              </h3>
              <p class="mb-2 text-sm text-gray-600 dark:text-gray-300">
                {{ product.description || "Tidak ada deskripsi." }}
              </p>
              <div class="mb-2 flex items-center justify-between text-sm">
                <span class="text-gray-700 dark:text-gray-300">
                  Kategori:
                  <span class="font-medium">{{
                    categories.find((c) => c.id === product.category_id)?.name || "N/A"
                  }}</span>
                </span>
                <Badge variant="outline" class="text-gray-700 dark:text-gray-300">
                  SKU: {{ product.sku || "N/A" }}
                </Badge>
              </div>
              <div class="mb-3 flex items-center justify-between text-sm">
                <span class="text-gray-700 dark:text-gray-300">
                  Stok:
                  <span class="font-medium">{{ product.stock }}</span>
                </span>
                <span
                  :class="{
                    'text-red-500': product.stock <= product.min_stock,
                    'text-orange-500':
                      product.stock > product.min_stock && product.stock < 10,
                    'text-green-500': product.stock >= 10,
                  }"
                  class="font-medium"
                >
                  {{
                    product.stock <= product.min_stock
                      ? "Stok Rendah!"
                      : product.stock < 10
                        ? "Stok Sedang"
                        : "Stok Aman"
                  }}
                </span>
              </div>
              <p class="text-xl font-bold text-green-600 dark:text-green-400">
                {{ formatCurrency(product.price) }}
              </p>
            </div>
          </Card>
        </div>

      <!-- Delete Confirmation Dialog -->
      <Dialog :open="isConfirmDeleteOpen" @update:open="isConfirmDeleteOpen = $event">
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Konfirmasi Hapus Produk</DialogTitle>
            <DialogDescription>
              Apakah Anda yakin ingin menghapus produk ini? Tindakan ini tidak dapat
              dibatalkan.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" @click="isConfirmDeleteOpen = false">Batal</Button>
            <Button
              variant="destructive"
              @click="deleteProductConfirmed"
              :disabled="loading"
            >
              <span v-if="loading">Menghapus...</span>
              <span v-else>Hapus</span>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
    <Toaster />
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  title: 'Produk - Aplikasi Kasir'
})
import { ref, onMounted } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { toast } from 'vue-sonner';
import { Toaster } from '@/components/ui/sonner';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import 'vue-sonner/style.css' // vue-sonner v2 requires this importx
import { ImageUpload } from '@/components/ui/image-upload';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogClose,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MoreHorizontal, Edit, Trash2 } from "lucide-vue-next";

interface Product {
  id: string;
  name: string;
  description: string | null;
  category_id: string | null;
  sku: string | null;
  barcode: string | null;
  price: number;
  cost: number | null;
  stock: number;
  min_stock: number;
  image_url: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  imageFile?: File | null;
}

interface Category {
  id: string;
  name: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const products = ref<Product[]>([]);
const categories = ref<Category[]>([]);
const productForm = ref({
  id: "",
  name: "",
  description: "",
  category_id: null as string | null,
  sku: "",
  barcode: "",
  price: 0,
  cost: 0,
  stock: 0,
  min_stock: 0,
  image_url: "",
  is_active: false,
  imageFile: null as File | null,
});

const pageLoading = ref(true); // Controls the loading state for the entire page
const isEditing = ref(false);
const loading = ref(false);
const hasAdminOrManagerRole = ref(false);
const uploadingImage = ref(false);
const fileInputRef = ref<HTMLInputElement | null>(null);
const isProductFormOpen = ref(false); // Controls the add/edit product dialog
const isConfirmDeleteOpen = ref(false); // Controls the delete confirmation dialog
const productToDeleteId = ref<string | null>(null); // Stores the ID of the product to be deleted

const fetchProducts = async () => {
  loading.value = true;
  try {
    const { data, error } = await supabase
      .from("products")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    products.value = data as Product[];
  } catch (error: any) {
    toast.error("Gagal memuat produk!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const fetchCategories = async () => {
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("id, name")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw error;
    categories.value = data as Category[];
  } catch (error: any) {
    toast.error("Gagal memuat kategori!", {
      description: error.message,
    });
  }
};

const checkUserRole = async () => {
  if (!user.value) {
    hasAdminOrManagerRole.value = false;
    return;
  }
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.value.id)
    .single();

  if (error) {
    toast.error("Gagal memeriksa peran pengguna!", {
      description: error.message,
    });
    hasAdminOrManagerRole.value = false;
    return;
  }
  if (!data) {
    toast.error("Data profil pengguna tidak ditemukan.");
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data?.role === "admin" || data?.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    toast.warning("Anda tidak memiliki izin untuk mengakses halaman ini.", {
      description: "Silakan hubungi administrator untuk mendapatkan akses.",
    });
  }
};

const saveProduct = async () => {
  loading.value = true;
  uploadingImage.value = false;

  try {
    let imageUrl = productForm.value.image_url;

    if (productForm.value.imageFile) {
      uploadingImage.value = true;
      const file = productForm.value.imageFile;
      const fileExt = file.name.split(".").pop();
      const fileName = `${Date.now()}.${fileExt}`;
      const filePath = `product_images/${fileName}`;

      const { error: uploadError, data: uploadData } = await supabase.storage
        .from("product_images")
        .upload(filePath, file, {
          cacheControl: "3600",
          upsert: false,
        });

      if (uploadError) {
        throw uploadError;
      }

      const { data: publicUrlData } = supabase.storage
        .from("product_images")
        .getPublicUrl(filePath);

      imageUrl = publicUrlData.publicUrl;
      uploadingImage.value = false;
    } else if (
      productForm.value.image_url &&
      !productForm.value.image_url.startsWith("blob:")
    ) {
      // If image_url exists but no new file is selected, keep the existing URL
      imageUrl = productForm.value.image_url;
    } else {
      // If no image_url and no new file, set to null
      imageUrl = null;
    }

    const productData = {
      name: productForm.value.name,
      description: productForm.value.description,
      category_id: productForm.value.category_id,
      sku: productForm.value.sku,
      barcode: productForm.value.barcode,
      price: productForm.value.price,
      cost: productForm.value.cost,
      stock: productForm.value.stock,
      min_stock: productForm.value.min_stock,
      image_url: imageUrl,
      is_active: productForm.value.is_active,
    };

    if (isEditing.value) {
      const { error } = await supabase
        .from("products")
        .update({ ...productData, updated_at: new Date().toISOString() })
        .eq("id", productForm.value.id);
      if (error) throw error;
      toast.success("Produk berhasil diperbarui!", {
        description: `Produk ${productForm.value.name} telah berhasil diperbarui.`,
      });
    } else {
      const { error } = await supabase.from("products").insert(productData);
      if (error) throw error;
      toast.success("Produk berhasil ditambahkan!", {
        description: `Produk ${productForm.value.name} telah berhasil ditambahkan.`,
      });
    }
    resetForm();
    await fetchProducts();
    isProductFormOpen.value = false; // Close the dialog on success
  } catch (error: any) {
    toast.error("Gagal menyimpan produk!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
    uploadingImage.value = false;
  }
};

const addNewProduct = () => {
  resetForm();
  isProductFormOpen.value = true;
};

const editProduct = (product: Product) => {
  isEditing.value = true;
  productForm.value = { ...product, imageFile: null, is_active: product.is_active }; // Clear imageFile and explicitly set is_active when editing
  if (fileInputRef.value) {
    fileInputRef.value.value = ""; // Clear the file input
  }
  isProductFormOpen.value = true; // Open the dialog for editing
};

const cancelEdit = () => {
  resetForm();
  isProductFormOpen.value = false; // Close the dialog on cancel
};

const confirmDeleteProduct = (id: string) => {
  productToDeleteId.value = id;
  isProductFormOpen.value = false; // Close the product form dialog
  isConfirmDeleteOpen.value = true;
};

const deleteProductConfirmed = async () => {
  if (!productToDeleteId.value) return;

  loading.value = true;
  try {
    const { error } = await supabase
      .from("products")
      .delete()
      .eq("id", productToDeleteId.value);
    if (error) throw error;
    loading.value = false; // Set loading to false before closing dialog
    isConfirmDeleteOpen.value = false; // Close the confirmation dialog
    productToDeleteId.value = null; // Clear the ID
    toast.success("Produk berhasil dihapus!", {
      description: "Produk telah berhasil dihapus dari daftar.",
    });
    await fetchProducts();
  } catch (error: any) {
    toast.error("Gagal menghapus produk!", {
      description: error.message,
    });
  } finally {
    loading.value = false;
  }
};

const resetForm = () => {
  isEditing.value = false;
  productForm.value = {
    id: "",
    name: "",
    description: "",
    category_id: null,
    sku: "",
    barcode: "",
    price: 0,
    cost: 0,
    stock: 0,
    min_stock: 0,
    image_url: "",
    is_active: true,
    imageFile: null,
  };
  if (fileInputRef.value) {
    fileInputRef.value.value = ""; // Clear the file input
  }
};

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

const handleFileChange = (file: File | null) => {
  productForm.value.imageFile = file;
  if (file) {
    productForm.value.image_url = URL.createObjectURL(file); // For immediate preview
  } else {
    productForm.value.image_url = "";
  }
};

const removeImage = () => {
  productForm.value.imageFile = null;
  productForm.value.image_url = "";
  // The ImageUpload component handles clearing its internal file input
};

const formatDate = (dateString: string) => {
  const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  };
  return new Date(dateString).toLocaleDateString("id-ID", options);
};

onMounted(async () => {
  pageLoading.value = true; // Start loading state
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
      await fetchProducts();
    }
  } catch (error: any) {
    toast.error("Terjadi kesalahan saat memuat data awal!", {
      description: error.message,
    });
  } finally {
    pageLoading.value = false; // End loading state
  }
});

watch(user, async (newUser) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
      await fetchProducts();
    }
  } else {
    hasAdminOrManagerRole.value = false;
    products.value = [];
    categories.value = [];
  }
});
</script>

<style scoped>
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: #3b82f6; /* Blue-500 */
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
