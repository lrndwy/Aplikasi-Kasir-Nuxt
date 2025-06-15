<template>
  <div class="flex flex-col min-h-screen bg-gray-100 dark:bg-gray-900 p-4">
    <h1 class="text-3xl font-bold mb-6 text-gray-900 dark:text-white">
      Laporan Stok Produk
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
      <div class="flex gap-4 mb-6">
        <div>
          <Label for="categoryFilter" class="mb-2">Filter Kategori</Label>
          <Select v-model="selectedCategoryId">
            <SelectTrigger id="categoryFilter" class="bg-white dark:bg-gray-950">
              <SelectValue
                :placeholder="
                  selectedCategoryId === 'all'
                    ? 'Semua Kategori'
                    : categories.find((c) => c.id === selectedCategoryId)?.name ||
                      'Semua Kategori'
                "
              />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Semua Kategori</SelectItem>
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
        <div>
          <Label for="stockStatus" class="mb-2">Status Stok</Label>
          <Select v-model="stockStatusFilter">
            <SelectTrigger id="stockStatus" class="bg-white dark:bg-gray-950">
              <SelectValue
                :placeholder="
                  stockStatusFilter === 'all' ? 'Semua Status' : stockStatusFilter
                "
              />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Semua Status</SelectItem>
              <SelectItem value="in_stock">Tersedia</SelectItem>
              <SelectItem value="low_stock">Stok Rendah</SelectItem>
              <SelectItem value="out_of_stock">Habis</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>
      <div v-if="errorMessage" class="text-red-500 text-sm mb-4">
        {{ errorMessage }}
      </div>

      <!-- Product Stock Details Table -->
      <div class="bg-white dark:bg-gray-800 shadow-md rounded-lg p-6">
        <h2 class="text-2xl font-semibold mb-4 text-gray-900 dark:text-white">
          Detail Stok Produk
        </h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Nama Produk</TableHead>
              <TableHead>Kategori</TableHead>
              <TableHead>Harga Jual</TableHead>
              <TableHead>Stok</TableHead>
              <TableHead>Stok Minimum</TableHead>
              <TableHead>Status Stok</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <TableRow v-for="product in filteredProducts" :key="product.id">
              <TableCell>{{ product.name }}</TableCell>
              <TableCell>{{
                categories.find((c) => c.id === product.category_id)?.name || "N/A"
              }}</TableCell>
              <TableCell>{{ formatCurrency(product.price) }}</TableCell>
              <TableCell>{{ product.stock }}</TableCell>
              <TableCell>{{ product.min_stock }}</TableCell>
              <TableCell>
                <Badge :variant="getStockStatusVariant(product.stock, product.min_stock)">
                  {{ getStockStatus(product.stock, product.min_stock) }}
                </Badge>
              </TableCell>
            </TableRow>
            <TableRow v-if="filteredProducts.length === 0 && !loading">
              <TableCell colspan="6" class="text-center text-gray-500 dark:text-gray-400">
                Tidak ada data stok produk untuk kriteria ini.
              </TableCell>
            </TableRow>
          </TableBody>
        </Table>
        <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 mt-4">
          Memuat data stok produk...
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from "vue";
import { useSupabaseClient, useSupabaseUser } from "#imports";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

interface Product {
  id: string;
  name: string;
  category_id: string | null;
  price: number;
  stock: number;
  min_stock: number;
  is_active: boolean;
}

interface Category {
  id: string;
  name: string;
}

const supabase = useSupabaseClient();
const user = useSupabaseUser();

const pageLoading = ref(true);
const products = ref<Product[]>([]);
const categories = ref<Category[]>([]);

const selectedCategoryId = ref("all");
const stockStatusFilter = ref("all");

const loading = ref(false);
const errorMessage = ref("");
const hasAdminOrManagerRole = ref(false);

const fetchProductStockData = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    let query = supabase.from("products").select("*").order("name", { ascending: true });

    if (selectedCategoryId.value && selectedCategoryId.value !== "all") {
      query = query.eq("category_id", selectedCategoryId.value);
    }
    // Note: Stock status filtering will be done client-side on the computed property

    const { data, error } = await query;

    if (error) throw error;
    products.value = data as Product[];
  } catch (error: any) {
    errorMessage.value = error.message;
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
    console.error("Error fetching categories:", error.message);
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
    console.error("Error fetching user role:", error.message);
    hasAdminOrManagerRole.value = false;
    return;
  }
  hasAdminOrManagerRole.value = data.role === "admin" || data.role === "manager";
  if (!hasAdminOrManagerRole.value) {
    errorMessage.value = "Anda tidak memiliki izin untuk mengakses halaman ini.";
  }
};

const getStockStatus = (stock: number, minStock: number) => {
  if (stock <= 0) {
    return "Habis";
  } else if (stock <= minStock) {
    return "Stok Rendah";
  } else {
    return "Tersedia";
  }
};

const getStockStatusVariant = (stock: number, minStock: number) => {
  if (stock <= 0) {
    return "destructive";
  } else if (stock <= minStock) {
    return "secondary";
  } else {
    return "default";
  }
};

const filteredProducts = computed(() => {
  if (stockStatusFilter.value === "all") {
    return products.value;
  }
  return products.value.filter((product) => {
    const status = getStockStatus(product.stock, product.min_stock);
    if (stockStatusFilter.value === "in_stock" && status === "Tersedia") return true;
    if (stockStatusFilter.value === "low_stock" && status === "Stok Rendah") return true;
    if (stockStatusFilter.value === "out_of_stock" && status === "Habis") return true;
    return false;
  });
});

const formatCurrency = (value: number) => {
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
};

onMounted(async () => {
  pageLoading.value = true;
  try {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
      await fetchProductStockData(); // Initial load
    }
  } catch (error) {
    console.error("Error during initial setup:", error);
  } finally {
    pageLoading.value = false;
  }
});

watch([user, selectedCategoryId, stockStatusFilter], async ([newUser]) => {
  if (newUser) {
    await checkUserRole();
    if (hasAdminOrManagerRole.value) {
      await fetchCategories();
      await fetchProductStockData(); // Re-fetch data when filters change
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
